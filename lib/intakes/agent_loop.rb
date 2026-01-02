require "anthropic"

module Intakes
  class AgentLoop
    MODEL = "claude-haiku-4-5-20251001"
    MAX_ITERATIONS = 10

    def initialize(session:, on_delta: nil, on_tool_use: nil)
      @session = session
      @on_delta = on_delta
      @on_tool_use = on_tool_use
      @tools = [
        Intakes::Tools::RecordResponse.new(session),
        Intakes::Tools::CompleteIntake.new(session)
      ]
      @client = Anthropic::Client.new(
        api_key: Rails.application.credentials.dig(:anthropic, :api_key)
      )
    end

    def process_user_message(content)
      @session.intake_messages.create!(role: :user, content: content)

      assistant_content = run_loop
      @session.intake_messages.create!(role: :assistant, content: assistant_content)

      assistant_content
    end

    def start_conversation
      assistant_content = run_loop
      @session.intake_messages.create!(role: :assistant, content: assistant_content)

      assistant_content
    end

    private

    def run_loop
      messages = build_messages
      full_response_text = ""
      iterations = 0

      loop do
        iterations += 1
        break if iterations > MAX_ITERATIONS

        response_text, tool_uses = stream_request(messages)
        full_response_text += response_text

        break if tool_uses.empty?

        tool_results = execute_tools(tool_uses)

        messages << { role: "assistant", content: build_assistant_content(response_text, tool_uses) }
        messages << { role: "user", content: tool_results }
      end

      full_response_text
    end

    def stream_request(messages)
      response_text = ""
      tool_uses = []
      current_tool_use = nil

      stream = @client.messages.stream_raw(
        model: MODEL,
        max_tokens: 4096,
        system: system_prompt,
        messages: messages,
        tools: @tools.map(&:definition)
      )

      stream.each do |event|
        case event.type
        when :content_block_start
          if event.content_block.type == :tool_use
            current_tool_use = {
              id: event.content_block.id,
              name: event.content_block.name,
              input_json: ""
            }
          end

        when :content_block_delta
          if event.delta.type == :text_delta
            text = event.delta.text
            response_text += text
            @on_delta&.call(text)
          elsif event.delta.type == :input_json_delta
            current_tool_use[:input_json] += event.delta.partial_json if current_tool_use
          end

        when :content_block_stop
          if current_tool_use
            current_tool_use[:input] = JSON.parse(current_tool_use[:input_json]) rescue {}
            tool_uses << current_tool_use
            @on_tool_use&.call(current_tool_use[:name])
            current_tool_use = nil
          end

        when :message_stop
          break
        end
      end

      [response_text, tool_uses]
    end

    def execute_tools(tool_uses)
      tool_uses.map do |tool_use|
        tool = @tools.find { |t| t.definition[:name] == tool_use[:name] }

        result = if tool
          tool.execute(tool_use[:input])
        else
          "エラー: ツール '#{tool_use[:name]}' が見つかりません"
        end

        {
          type: "tool_result",
          tool_use_id: tool_use[:id],
          content: result
        }
      end
    end

    def build_assistant_content(text, tool_uses)
      content = []
      content << { type: "text", text: text } if text.present?

      tool_uses.each do |tool_use|
        content << {
          type: "tool_use",
          id: tool_use[:id],
          name: tool_use[:name],
          input: tool_use[:input]
        }
      end

      content
    end

    def build_messages
      messages = @session.intake_messages.order(:created_at).map do |msg|
        { role: msg.role, content: msg.content }
      end

      # Anthropic APIは最低1つのメッセージが必要
      if messages.empty?
        messages << { role: "user", content: "問診を始めてください。" }
      end

      messages
    end

    def system_prompt
      intake = @session.intake
      items = intake.intake_items.map do |item|
        desc = item.description.present? ? "（#{item.description}）" : ""
        "- #{item.name}#{desc}"
      end.join("\n")

      recorded = @session.intake_responses.includes(:intake_item).map do |resp|
        "- #{resp.intake_item.name}: 記録済み"
      end.join("\n")

      <<~PROMPT
        あなたは問診を行うアシスタントです。
        以下の項目について、相談者から情報を聞き出してください。

        【問診タイトル】
        #{intake.title}

        【聞き出す項目】
        #{items}

        【すでに記録済みの項目】
        #{recorded.presence || "なし"}

        【ルール】
        - 1項目ずつ丁寧に聞いてください
        - 相談者の回答から十分な情報が得られたら、record_response ツールで記録してください
        - すべての項目が完了したら complete_intake を呼んでください
        - 優しく、共感的な態度で接してください
      PROMPT
    end
  end
end

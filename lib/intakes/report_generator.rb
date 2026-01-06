require "anthropic"

module Intakes
  class ReportGenerator
    MODEL = "claude-opus-4-5-20251101"

    def initialize(session)
      @session = session
      @client = Anthropic::Client.new(
        api_key: Rails.application.credentials.dig(:anthropic, :api_key)
      )
    end

    def generate
      response = @client.messages.create(
        model: MODEL,
        max_tokens: 4096,
        system: system_prompt,
        messages: [{ role: "user", content: build_user_message }]
      )

      content = response.content.first.text

      @session.create_intake_report!(content: content)
    end

    private

    def system_prompt
      <<~PROMPT
        あなたは問診結果をまとめるアシスタントです。
        与えられた問診の回答情報をもとに、読みやすい報告書を作成してください。

        【報告書の形式】
        - Markdown形式で記述
        - 問診タイトルを見出しとして記載
        - 各項目と回答を整理して記載
        - 必要に応じて要約や補足を追加
        - 専門家（相談員、カウンセラー等）が読むことを想定
      PROMPT
    end

    def build_user_message
      intake = @session.intake
      responses = @session.intake_responses.includes(:intake_item)

      items_text = responses.map do |resp|
        "【#{resp.intake_item.name}】\n#{resp.content}"
      end.join("\n\n")

      description_section = intake.description.present? ? "\n## 問診の説明\n#{intake.description}\n" : ""
      report_format_section = intake.report_format.present? ? "\n## 報告書の形式指定\n#{intake.report_format}\n" : ""

      <<~MESSAGE
        以下の問診結果をもとに報告書を作成してください。

        ## 問診タイトル
        #{intake.title}
        #{description_section}#{report_format_section}
        ## 回答内容
        #{items_text}
      MESSAGE
    end
  end
end

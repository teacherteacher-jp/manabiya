module Llm
  class AgentLoop
    MAX_ITERATIONS = 10
    MAX_TOKENS_BUDGET = 50_000

    attr_reader :iterations, :total_tokens

    # @param claude_client [Llm::Claude] Claudeクライアント
    # @param discord_bot [Discord::Bot] Discordボットインスタンス
    # @param logger [Logger] ロガー（デフォルト: 標準出力）
    # @param allowed_category_id [String, nil] 許可されたカテゴリID（認可制御用）
    # @param on_progress [Proc, nil] 進捗通知用コールバック（オプション）
    def initialize(claude_client, discord_bot:, logger: Logger.new($stdout), allowed_category_id: nil, on_progress: nil)
      @claude = claude_client
      @discord_bot = discord_bot
      @logger = logger
      @allowed_category_id = allowed_category_id
      @on_progress = on_progress
      @tools = load_tools
      @iterations = 0
      @total_tokens = 0
    end

    # Agentループを実行
    # @param user_message [String] ユーザーからのメッセージ
    # @param system_prompt [String] システムプロンプト
    # @return [String] Claudeからの最終応答
    def run(user_message:, system_prompt:)
      messages = [{ role: "user", content: user_message }]

      loop do
        @iterations += 1
        @logger.info "🔄 Agent iteration #{@iterations}/#{MAX_ITERATIONS}"

        break if @iterations > MAX_ITERATIONS
        break if @total_tokens > MAX_TOKENS_BUDGET

        # Claude APIをツール定義付きで呼び出し
        response = @claude.messages_with_tools(
          messages: messages,
          system: system_prompt,
          tools: @tools.map(&:definition),
          max_tokens: 4096
        )

        # usage.input_tokens と usage.output_tokens を合計
        tokens_used = response.usage.input_tokens + response.usage.output_tokens
        @total_tokens += tokens_used
        @logger.info "📊 Tokens used: #{tokens_used} (total: #{@total_tokens}/#{MAX_TOKENS_BUDGET})"

        case response.stop_reason
        when :end_turn
          # Claudeが完了と判断
          @logger.info "✅ Agent completed (end_turn)"
          return extract_final_answer(response)

        when :tool_use
          # Claudeがツールを使いたい
          @logger.info "🔧 Tool use requested"
          tool_results = execute_tools(response)

          # 会話履歴に追加
          # assistantのメッセージ（tool_useブロックを含む）
          messages << { role: "assistant", content: response.content }
          # userのメッセージ（tool_resultブロック）
          messages << { role: "user", content: tool_results }

        when :max_tokens
          # トークン上限、継続
          @logger.info "⚠️ Max tokens reached, continuing..."
          messages << { role: "assistant", content: response.content }
        end
      end

      @logger.error "❌ Agent exceeded limits (iterations: #{@iterations}, tokens: #{@total_tokens})"
      "申し訳ございません。処理が複雑で完了できませんでした。"
    end

    private

    # 利用可能なツールをロード
    # @return [Array<Object>] ツールインスタンスの配列
    def load_tools
      [
        # Discord専用ツール（Botインスタンスとカテゴリ制限を注入）
        Discord::Tools::SearchMessages.new(@discord_bot, allowed_category_id: @allowed_category_id),
        Discord::Tools::GetChannelInfo.new(@discord_bot),
        Discord::Tools::GetThreadContext.new(@discord_bot),
        Discord::Tools::GetMessagesAround.new(@discord_bot, allowed_category_id: @allowed_category_id),
        # 汎用ツール（状態を持たないが、統一性のためインスタンス化）
        Tools::Calculator.new,
        Tools::GetCurrentTime.new
      ]
    end

    # ツールを実行
    # @param response [Anthropic::Models::Message] Claudeのレスポンス
    # @return [Array<Hash>] ツール実行結果の配列
    def execute_tools(response)
      tool_uses = response.content.select { |block| block.type == :tool_use }
      @logger.info "Found #{tool_uses.size} tool use(s)"

      results = tool_uses.map do |tool_use|
        @logger.info "🔧 Tool: #{tool_use.name}(#{tool_use.input.inspect})"

        # 進捗通知
        if @on_progress
          message = progress_message(tool_use.name, tool_use.input)
          @on_progress.call(message)
        end

        tool = @tools.find { |t| t.definition[:name] == tool_use.name }

        unless tool
          @logger.error "Tool not found: #{tool_use.name}"
          next {
            type: "tool_result",
            tool_use_id: tool_use.id,
            content: "エラー: ツール '#{tool_use.name}' が見つかりません",
            is_error: true
          }
        end

        # ツールを実行（すべてインスタンスメソッド）
        result = tool.execute(tool_use.input)
        @logger.info "✅ Tool result: #{result.to_s.slice(0, 100)}..."

        {
          type: "tool_result",
          tool_use_id: tool_use.id,
          content: result
        }
      rescue => e
        @logger.error "Tool failed: #{e.class} - #{e.message}"
        @logger.error e.backtrace.join("\n")
        {
          type: "tool_result",
          tool_use_id: tool_use.id,
          content: "エラー: #{e.message}",
          is_error: true
        }
      end

      results.compact
    end

    # 最終応答をレスポンスから抽出
    # @param response [Anthropic::Models::Message] Claudeのレスポンス
    # @return [String] 抽出されたテキスト
    def extract_final_answer(response)
      response.content
        .select { |block| block.type == :text }
        .map(&:text)
        .join("\n")
    end

    # ツールの実行に応じた進捗メッセージを生成
    # @param tool_name [String] ツール名
    # @param input [Hash] ツールへの入力パラメータ
    # @return [String] 進捗メッセージ
    def progress_message(tool_name, input)
      case tool_name
      when "search_discord_messages"
        query = input["query"] || input[:query]
        "🔍 Discordを「#{query}」で検索しています..."
      when "get_messages_around"
        "📄 メッセージの前後を確認しています..."
      when "get_channel_info"
        "ℹ️ チャンネル情報を取得しています..."
      when "get_thread_context"
        "💬 スレッドの履歴を確認しています..."
      when "calculate"
        "🧮 計算しています..."
      when "get_current_time"
        "🕐 現在時刻を取得しています..."
      else
        "🔧 #{tool_name}を実行しています..."
      end
    end
  end
end

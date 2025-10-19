module Discord
  module Tools
    class GetThreadContext
      def initialize(bot)
        @bot = bot
      end

      # Anthropic Tool Use API形式の定義
      def self.definition
        {
          name: "get_thread_context",
          description: "Discordスレッド内の会話履歴を取得します。現在のスレッドや特定のスレッドの過去のやり取りを確認できます。",
          input_schema: {
            type: "object",
            properties: {
              thread_id: {
                type: "string",
                description: "スレッドID（チャンネルID）"
              },
              limit: {
                type: "integer",
                description: "取得するメッセージ数（デフォルト: 10）",
                default: 10
              }
            },
            required: ["thread_id"]
          }
        }
      end

      # AgentLoopから呼び出されるインスタンスメソッド
      def definition
        self.class.definition
      end

      # ツールの実行（インスタンスメソッド）
      # @param input [Hash] ツールへの入力
      # @return [String] スレッドの会話履歴
      def execute(input)
        thread_id = input["thread_id"] || input[:thread_id]
        limit = input["limit"] || input[:limit] || 10

        # Discord APIでメッセージを取得
        # get メソッドは既存の Discord::Bot クラスにある
        response = @bot.get("/channels/#{thread_id}/messages?limit=#{limit}")

        unless response.status == 200
          return "スレッドID「#{thread_id}」のメッセージ取得に失敗しました。"
        end

        messages = JSON.parse(response.body)

        if messages.empty?
          return "スレッド内にメッセージが見つかりませんでした。"
        end

        format_thread_messages(messages)
      rescue => e
        Rails.logger.error "GetThreadContext failed: #{e.class} - #{e.message}"
        "スレッド履歴の取得中にエラーが発生しました: #{e.message}"
      end

      private

      # メッセージを読みやすい形式にフォーマット
      # @param messages [Array<Hash>] メッセージの配列（新しい順）
      # @return [String] フォーマットされた会話履歴
      def self.format_thread_messages(messages)
        # 古い順に並び替え（会話の流れが自然になる）
        sorted_messages = messages.reverse

        formatted = sorted_messages.map do |msg|
          author = msg.dig("author", "username") || "不明なユーザー"
          content = msg["content"] || "(コンテンツなし)"
          timestamp = Time.parse(msg["timestamp"]).strftime("%Y-%m-%d %H:%M") rescue "不明な日時"

          "#{timestamp} | #{author}\n#{content}"
        end.join("\n\n---\n\n")

        "【スレッド会話履歴】（全#{sorted_messages.size}件）\n\n#{formatted}"
      end
    end
  end
end

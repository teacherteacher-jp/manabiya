module Discord
  module Tools
    class GetMessagesAround
      def initialize(bot)
        @bot = bot
      end

      # Anthropic Tool Use API形式の定義
      def self.definition
        {
          name: "get_messages_around",
          description: "指定したメッセージIDの前後のメッセージを取得します。検索で見つけたメッセージの文脈（前後の会話）を確認したい場合に使用します。",
          input_schema: {
            type: "object",
            properties: {
              channel_id: {
                type: "string",
                description: "チャンネルID（検索結果から取得）"
              },
              message_id: {
                type: "string",
                description: "基準となるメッセージID（検索結果から取得）"
              },
              limit: {
                type: "integer",
                description: "取得する最大メッセージ数（1-100、デフォルト: 10）",
                default: 10
              }
            },
            required: ["channel_id", "message_id"]
          }
        }
      end

      # AgentLoopから呼び出されるインスタンスメソッド
      def definition
        self.class.definition
      end

      # ツールの実行（インスタンスメソッド）
      # @param input [Hash] ツールへの入力
      # @return [String] メッセージのリスト
      def execute(input)
        channel_id = input["channel_id"] || input[:channel_id]
        message_id = input["message_id"] || input[:message_id]
        limit = input["limit"] || input[:limit] || 10

        # limitを1-100の範囲に制限
        limit = [[limit, 1].max, 100].min

        messages = @bot.get_messages_around(
          channel_id: channel_id,
          message_id: message_id,
          limit: limit
        )

        if messages.empty?
          return "指定されたメッセージの前後のメッセージは取得できませんでした。"
        end

        format_messages(messages, message_id)
      rescue => e
        Rails.logger.error "GetMessagesAround failed: #{e.class} - #{e.message}"
        "メッセージ取得中にエラーが発生しました: #{e.message}"
      end

      private

      # メッセージを読みやすい形式にフォーマット
      # @param messages [Array<Hash>] メッセージの配列
      # @param target_message_id [String] 基準となるメッセージID
      # @return [String] フォーマットされた結果
      def format_messages(messages, target_message_id)
        # タイムスタンプでソート（古い順）
        sorted_messages = messages.sort_by { |m| Time.parse(m["timestamp"]) }

        formatted = sorted_messages.map.with_index(1) do |msg, index|
          author = msg.dig("author", "username") || msg.dig("author", "global_name") || "不明なユーザー"
          content = msg["content"] || ""
          timestamp = Time.parse(msg["timestamp"]).strftime("%Y-%m-%d %H:%M") rescue "不明な日時"
          is_target = msg["id"] == target_message_id

          # contentが空の場合、embedsをチェック
          if content.empty? && msg["embeds"]&.any?
            embed = msg["embeds"].first
            content = "[Embed] #{embed["title"] || embed["description"]}"
          end

          marker = is_target ? " ★ [基準メッセージ]" : ""
          "[#{index}] #{timestamp} | #{author}#{marker}\n#{content.slice(0, 300)}"
        end.join("\n\n")

        "前後のメッセージ（#{sorted_messages.size}件）:\n\n#{formatted}"
      end
    end
  end
end

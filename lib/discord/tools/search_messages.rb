module Discord
  module Tools
    class SearchMessages
      def initialize(bot)
        @bot = bot
      end

      # Anthropic Tool Use API形式の定義
      def self.definition
        {
          name: "search_discord_messages",
          description: "Discordサーバー内の過去のメッセージを検索します。キーワードで検索し、関連するメッセージを見つけます。",
          input_schema: {
            type: "object",
            properties: {
              query: {
                type: "string",
                description: "検索キーワード（例: 'Rails', 'マイクチェック', 'エラー'）"
              },
              limit: {
                type: "integer",
                description: "最大取得件数（デフォルト: 5）",
                default: 5
              }
            },
            required: ["query"]
          }
        }
      end

      # AgentLoopから呼び出されるインスタンスメソッド
      def definition
        self.class.definition
      end

      # ツールの実行（インスタンスメソッド）
      # @param input [Hash] ツールへの入力
      # @return [String] 検索結果（JSON形式またはテキスト）
      def execute(input)
        query = input["query"] || input[:query]
        limit = input["limit"] || input[:limit] || 5

        # 既存のsearch_messages_in_serverメソッドを使用
        results = @bot.search_messages_in_server(
          query: query,
          limit: 30,  # 1チャンネルあたり30件
          max_results: limit
        )

        if results.empty?
          return "「#{query}」に関する過去のメッセージは見つかりませんでした。"
        end

        format_results(results, query)
      rescue => e
        Rails.logger.error "SearchMessages failed: #{e.class} - #{e.message}"
        "検索中にエラーが発生しました: #{e.message}"
      end

      private

      # 検索結果を読みやすい形式にフォーマット
      # @param results [Array<Hash>] 検索結果
      # @param query [String] 検索キーワード
      # @return [String] フォーマットされた結果
      def format_results(results, query)
        formatted = results.map.with_index(1) do |msg, index|
          author = msg.dig("author", "username") || "不明なユーザー"
          content = msg["content"] || ""
          timestamp = Time.parse(msg["timestamp"]).strftime("%Y-%m-%d %H:%M") rescue "不明な日時"

          "[#{index}] #{timestamp} | #{author}\n#{content.slice(0, 200)}"
        end.join("\n\n")

        "「#{query}」に関する検索結果（#{results.size}件）:\n\n#{formatted}"
      end
    end
  end
end

module Discord
  module Tools
    class SearchMessages
      def initialize(bot, allowed_category_id: nil)
        @bot = bot
        @allowed_category_id = allowed_category_id
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

        # カテゴリ制限がある場合、そのカテゴリ内のチャンネルIDを取得
        channel_ids = nil
        if @allowed_category_id
          channel_ids = get_category_channel_ids(@allowed_category_id)
          Rails.logger.info "Restricting search to category #{@allowed_category_id}: #{channel_ids.size} channels"
        end

        # 新しいGuild Search APIを使用（search_messages_in_server2）
        result = @bot.search_messages_in_server2(
          query: query,
          limit: [limit, 25].min,  # 最大25件
          sort_by: "timestamp",
          sort_order: "desc",
          channel_ids: channel_ids
        )

        if result[:error]
          return "検索中にエラーが発生しました: #{result[:error]}"
        end

        messages = result[:messages]

        if messages.empty?
          return "「#{query}」に関する過去のメッセージは見つかりませんでした。"
        end

        format_results(messages, query, result[:total_results])
      rescue => e
        Rails.logger.error "SearchMessages failed: #{e.class} - #{e.message}"
        "検索中にエラーが発生しました: #{e.message}"
      end

      private

      # カテゴリ内の全チャンネルIDを取得
      # @param category_id [String] カテゴリID
      # @return [Array<String>] チャンネルIDの配列
      def get_category_channel_ids(category_id)
        all_channels = @bot.get_all_channels
        category_channels = all_channels.select { |ch| ch["parent_id"] == category_id }

        channel_ids = []

        # 通常チャンネル（type: 0）
        text_channels = category_channels.select { |ch| ch["type"] == 0 }
        channel_ids.concat(text_channels.map { |ch| ch["id"] })

        # Forumチャンネル（type: 15）
        # Guild Search APIはフォーラムチャンネルIDを指定すると、
        # その中の全スレッドを自動的に検索してくれる
        forum_channels = category_channels.select { |ch| ch["type"] == 15 }
        channel_ids.concat(forum_channels.map { |ch| ch["id"] })

        channel_ids
      end

      # 検索結果を読みやすい形式にフォーマット
      # @param results [Array<Hash>] 検索結果
      # @param query [String] 検索キーワード
      # @param total_results [Integer] サーバー内の総検索結果数
      # @return [String] フォーマットされた結果
      def format_results(results, query, total_results = nil)
        formatted = results.map.with_index(1) do |msg, index|
          author = msg.dig("author", "username") || msg.dig("author", "global_name") || "不明なユーザー"
          content = msg["content"] || ""
          timestamp = Time.parse(msg["timestamp"]).strftime("%Y-%m-%d %H:%M") rescue "不明な日時"
          channel_id = msg["channel_id"]

          # contentが空の場合、embedsをチェック
          if content.empty? && msg["embeds"]&.any?
            embed = msg["embeds"].first
            content = "[Embed] #{embed["title"] || embed["description"]}"
          end

          "[#{index}] #{timestamp} | #{author} (ch: #{channel_id})\n#{content.slice(0, 200)}"
        end.join("\n\n")

        result_text = "「#{query}」に関する検索結果（#{results.size}件"
        result_text += " / 全#{total_results}件" if total_results
        result_text += "）:\n\n#{formatted}"

        result_text
      end
    end
  end
end

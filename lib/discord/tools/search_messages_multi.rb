module Discord
  module Tools
    class SearchMessagesMulti
      MAX_QUERIES = 20
      SLEEP_BETWEEN_QUERIES = 1

      def initialize(bot, allowed_category_id: nil)
        @bot = bot
        @allowed_category_id = allowed_category_id
      end

      # Anthropic Tool Use API形式の定義
      def self.definition
        {
          name: "search_discord_messages_multi",
          description: "複数のキーワードで一括検索します。網羅的な調査（例: 「◯◯についてこれまでにどんな言及があったかまとめて」）に最適です。1回の呼び出しで複数の検索クエリを実行し、結果をまとめて返します。",
          input_schema: {
            type: "object",
            properties: {
              queries: {
                type: "array",
                items: { type: "string" },
                description: "検索キーワードの配列（最大20個）。関連する様々なキーワードを指定してください。例: ['React', 'hooks', 'useState', 'コンポーネント']"
              },
              limit_per_query: {
                type: "integer",
                description: "各クエリあたりの最大取得件数（デフォルト: 5、最大: 25）",
                default: 5
              }
            },
            required: ["queries"]
          }
        }
      end

      # AgentLoopから呼び出されるインスタンスメソッド
      def definition
        self.class.definition
      end

      # ツールの実行
      # @param input [Hash] ツールへの入力
      # @return [String] 検索結果
      def execute(input)
        queries = input["queries"] || input[:queries] || []
        limit_per_query = input["limit_per_query"] || input[:limit_per_query] || 5
        limit_per_query = [[limit_per_query, 25].min, 1].max  # 1-25の範囲

        # クエリ数の制限
        if queries.empty?
          return "検索キーワードが指定されていません。"
        end

        if queries.size > MAX_QUERIES
          queries = queries.take(MAX_QUERIES)
          Rails.logger.warn "SearchMessagesMulti: クエリ数が#{MAX_QUERIES}を超えたため、最初の#{MAX_QUERIES}件のみ実行します"
        end

        # カテゴリ制限がある場合、そのカテゴリ内のチャンネルIDを取得
        channel_ids = nil
        if @allowed_category_id
          channel_ids = get_category_channel_ids(@allowed_category_id)
          Rails.logger.info "SearchMessagesMulti: Restricting search to category #{@allowed_category_id}: #{channel_ids.size} channels"
        end

        # 各クエリを実行
        all_messages = []
        query_stats = []

        queries.each_with_index do |query, index|
          Rails.logger.info "SearchMessagesMulti: Executing query #{index + 1}/#{queries.size}: \"#{query}\""

          result = @bot.search_messages_in_server2(
            query: query,
            limit: limit_per_query,
            sort_by: "timestamp",
            sort_order: "desc",
            channel_ids: channel_ids
          )

          if result[:error]
            Rails.logger.warn "SearchMessagesMulti: Error for query \"#{query}\": #{result[:error]}"
            query_stats << { query: query, found: 0, total: 0, error: result[:error] }
          else
            messages = result[:messages] || []
            # 各メッセージに検索クエリを記録（後でデバッグ用）
            messages.each { |msg| msg["_matched_query"] = query }
            all_messages.concat(messages)
            query_stats << { query: query, found: messages.size, total: result[:total_results] || 0 }
          end

          # レート制限対策: 最後のクエリ以外はsleep
          if index < queries.size - 1
            sleep SLEEP_BETWEEN_QUERIES
          end
        end

        # 重複排除（message_idベース）
        unique_messages = all_messages.uniq { |msg| msg["id"] }
        duplicates_removed = all_messages.size - unique_messages.size

        # 時系列でソート（新しい順）
        sorted_messages = unique_messages.sort_by do |msg|
          Time.parse(msg["timestamp"]) rescue Time.at(0)
        end.reverse

        if sorted_messages.empty?
          return format_empty_result(queries, query_stats)
        end

        format_results(sorted_messages, queries, query_stats, duplicates_removed)
      rescue => e
        Rails.logger.error "SearchMessagesMulti failed: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.first(10).join("\n")
        "検索中にエラーが発生しました: #{e.message}"
      end

      private

      # カテゴリ内の全チャンネルIDを取得
      def get_category_channel_ids(category_id)
        all_channels = @bot.get_all_channels
        category_channels = all_channels.select { |ch| ch["parent_id"] == category_id }

        channel_ids = []

        # 通常チャンネル（type: 0）
        text_channels = category_channels.select { |ch| ch["type"] == 0 }
        channel_ids.concat(text_channels.map { |ch| ch["id"] })

        # Forumチャンネル（type: 15）
        forum_channels = category_channels.select { |ch| ch["type"] == 15 }
        channel_ids.concat(forum_channels.map { |ch| ch["id"] })

        channel_ids
      end

      # 結果が空の場合のフォーマット
      def format_empty_result(queries, query_stats)
        stats_text = query_stats.map do |stat|
          if stat[:error]
            "- 「#{stat[:query]}」: エラー (#{stat[:error]})"
          else
            "- 「#{stat[:query]}」: 0件"
          end
        end.join("\n")

        <<~TEXT
          検索キーワード #{queries.size}個で検索しましたが、関連するメッセージは見つかりませんでした。

          【検索結果サマリー】
          #{stats_text}
        TEXT
      end

      # 検索結果をフォーマット
      def format_results(messages, queries, query_stats, duplicates_removed)
        server_id = @bot.server_id

        # サマリー部分
        stats_text = query_stats.map do |stat|
          if stat[:error]
            "- 「#{stat[:query]}」: エラー (#{stat[:error]})"
          elsif stat[:total] > stat[:found]
            "- 「#{stat[:query]}」: #{stat[:found]}件取得 (全#{stat[:total]}件中)"
          else
            "- 「#{stat[:query]}」: #{stat[:found]}件"
          end
        end.join("\n")

        # メッセージ部分
        formatted_messages = messages.map.with_index(1) do |msg, index|
          author_name = Discord::Formatter.bold_display_name(msg["author"])
          channel_mention = msg["channel_id"] ? Discord::Formatter.mention_channel(msg["channel_id"]) : ""
          timestamp = Time.parse(msg["timestamp"]).strftime("%Y-%m-%d %H:%M") rescue "不明な日時"

          message_link = ""
          if msg["id"] && msg["channel_id"]
            message_link = Discord::Formatter.message_link(
              server_id: server_id,
              channel_id: msg["channel_id"],
              message_id: msg["id"]
            )
          end

          content = msg["content"] || ""
          if content.empty? && msg["embeds"]&.any?
            embed = msg["embeds"].first
            content = "[Embed] #{embed["title"] || embed["description"]}"
          end

          # マッチしたクエリを表示（参考情報として）
          matched_query = msg["_matched_query"]

          header = "[#{index}] #{timestamp} | #{author_name} in #{channel_mention}"
          header += " (検索: #{matched_query})" if matched_query
          header += "\n#{message_link}" if message_link.present?
          header += "\n#{content.slice(0, 300)}"

          header
        end.join("\n\n")

        # 全体をまとめる
        dedup_info = duplicates_removed > 0 ? "（重複#{duplicates_removed}件を除外）" : ""

        <<~TEXT
          【一括検索結果】#{queries.size}個のキーワードで検索し、#{messages.size}件のメッセージを取得しました#{dedup_info}

          【検索クエリ別サマリー】
          #{stats_text}

          【メッセージ一覧】（新しい順）
          #{formatted_messages}
        TEXT
      end
    end
  end
end

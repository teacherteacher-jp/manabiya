module Discord
  module Tools
    class RecentMessages
      def initialize(bot, allowed_category_id: nil)
        @bot = bot
        @allowed_category_id = allowed_category_id
      end

      # Anthropic Tool Use API形式の定義
      def self.definition
        {
          name: "get_recent_messages",
          description: "サーバー内の最近の投稿を時系列順に取得します。最近の話題やアクティビティを把握するのに便利です。",
          input_schema: {
            type: "object",
            properties: {
              limit: {
                type: "integer",
                description: "取得する件数（デフォルト: 25、最大: 100）",
                default: 25
              }
            },
            required: []
          }
        }
      end

      # AgentLoopから呼び出されるインスタンスメソッド
      def definition
        self.class.definition
      end

      # ツールの実行（インスタンスメソッド）
      # @param input [Hash] ツールへの入力
      # @return [String] 最近のメッセージ一覧
      def execute(input)
        limit = input["limit"] || input[:limit] || 25
        # 1-100の範囲に制限
        limit = [[limit, 1].max, 100].min

        # カテゴリ制限がある場合、そのカテゴリ内のチャンネルIDを取得
        channel_ids = nil
        if @allowed_category_id
          channel_ids = get_category_channel_ids(@allowed_category_id)
          Rails.logger.info "Restricting to category #{@allowed_category_id}: #{channel_ids.size} channels"
        end

        # Guild Search APIでスペース検索（全メッセージ対象）
        messages = fetch_recent_messages(limit, channel_ids)

        if messages.empty?
          return "最近の投稿が見つかりませんでした。"
        end

        format_results(messages)
      rescue => e
        Rails.logger.error "RecentMessages failed: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        "最近の投稿の取得中にエラーが発生しました: #{e.message}"
      end

      private

      # 最近のメッセージを取得（ページネーション対応）
      # @param limit [Integer] 取得件数
      # @param channel_ids [Array<String>, nil] チャンネルID配列（カテゴリ制限用）
      # @return [Array<Hash>] メッセージの配列
      def fetch_recent_messages(limit, channel_ids)
        all_messages = []
        page_size = 25 # Guild Search APIの1リクエスト最大件数
        pages = (limit.to_f / page_size).ceil

        pages.times do |page|
          offset = page * page_size
          remaining = limit - all_messages.size
          current_limit = [remaining, page_size].min

          result = @bot.search_messages_in_server2(
            query: " ",  # スペース1個で全メッセージ対象
            limit: current_limit,
            sort_by: "timestamp",
            sort_order: "desc",
            offset: offset,
            channel_ids: channel_ids
          )

          break if result[:error]
          break if result[:messages].empty?

          all_messages.concat(result[:messages])

          # レート制限対策で少し待つ（最後のページ以外）
          sleep 1 if page < pages - 1 && all_messages.size < limit
        end

        all_messages
      end

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
        forum_channels = category_channels.select { |ch| ch["type"] == 15 }
        channel_ids.concat(forum_channels.map { |ch| ch["id"] })

        channel_ids
      end

      # 検索結果を読みやすい形式にフォーマット
      # @param messages [Array<Hash>] メッセージの配列
      # @return [String] フォーマットされた結果
      def format_results(messages)
        server_id = @bot.server_id

        # 統計情報
        unique_users = messages.map { |m| m.dig("author", "username") }.compact.uniq
        time_range = if messages.size > 1
          first_time = Time.parse(messages.last["timestamp"]) rescue nil
          last_time = Time.parse(messages.first["timestamp"]) rescue nil
          if first_time && last_time
            duration = ((last_time - first_time) / 60).round
            duration_text = if duration < 60
              "#{duration}分"
            else
              hours = duration / 60
              minutes = duration % 60
              "#{hours}時間#{minutes}分"
            end
            " (過去#{duration_text})"
          else
            ""
          end
        else
          ""
        end

        header = "📋 最近の投稿 (#{messages.size}件#{time_range}、投稿者#{unique_users.size}人)\n\n"

        formatted = messages.map.with_index(1) do |msg, index|
          # ユーザー表示名
          author_name = Discord::Formatter.bold_display_name(msg["author"])

          # チャンネルメンション
          channel_mention = msg["channel_id"] ? Discord::Formatter.mention_channel(msg["channel_id"]) : ""

          # タイムスタンプ
          timestamp = Time.parse(msg["timestamp"]).strftime("%m/%d %H:%M") rescue "不明"

          # メッセージリンク
          message_link = ""
          if msg["id"] && msg["channel_id"]
            message_link = Discord::Formatter.message_link(
              server_id: server_id,
              channel_id: msg["channel_id"],
              message_id: msg["id"]
            )
          end

          # コンテンツ
          content = msg["content"] || ""
          if content.empty? && msg["embeds"]&.any?
            embed = msg["embeds"].first
            content = "[Embed] #{embed["title"] || embed["description"]}"
          end

          # 1行フォーマット（簡潔に）
          text = "[#{index}] #{timestamp} | #{author_name} in #{channel_mention}"
          text += "\n#{message_link}" if message_link.present?
          text += "\n#{content.slice(0, 150)}" # 150文字まで

          text
        end.join("\n\n")

        header + formatted
      end
    end
  end
end

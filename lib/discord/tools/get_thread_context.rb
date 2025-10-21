module Discord
  module Tools
    class GetThreadContext
      def initialize(bot, current_thread_id: nil)
        @bot = bot
        @current_thread_id = current_thread_id
      end

      # Anthropic Tool Use API形式の定義
      def self.definition
        {
          name: "get_thread_context",
          description: "Discordスレッド内の会話履歴を取得します。現在のスレッドや特定のスレッドの過去のやり取りを確認できます。thread_idを省略した場合は、現在のスレッドの履歴を取得します。",
          input_schema: {
            type: "object",
            properties: {
              thread_id: {
                type: "string",
                description: "スレッドID（チャンネルID）。省略した場合は現在のスレッドを使用します。"
              },
              limit: {
                type: "integer",
                description: "取得するメッセージ数（デフォルト: 10）",
                default: 10
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
      # @return [String] スレッドの会話履歴
      def execute(input)
        # thread_idが指定されていない場合は現在のスレッドIDを使用
        thread_id = input["thread_id"] || input[:thread_id] || @current_thread_id
        limit = input["limit"] || input[:limit] || 10

        # スレッドIDが取得できない場合はエラー
        unless thread_id
          return "エラー: スレッドIDが指定されていません。thread_idパラメータを指定するか、現在のスレッド内でこのツールを使用してください。"
        end

        # スレッド情報を取得して親チャンネルIDを確認
        thread_info_response = @bot.get("/channels/#{thread_id}")
        thread_info = JSON.parse(thread_info_response.body) if thread_info_response.status == 200

        # Discord APIでメッセージを取得
        response = @bot.get("/channels/#{thread_id}/messages?limit=#{limit}")

        unless response.status == 200
          error_message = parse_discord_error(response, thread_id)
          return error_message
        end

        messages = JSON.parse(response.body)

        # 親チャンネルから起点メッセージを取得（type: 11 公開スレッドの場合）
        starter_message = nil
        if thread_info && thread_info["parent_id"] && [11, 12].include?(thread_info["type"])
          starter_response = @bot.get("/channels/#{thread_info['parent_id']}/messages/#{thread_id}")
          if starter_response.status == 200
            starter_message = JSON.parse(starter_response.body)
          end
        end

        if messages.empty? && starter_message.nil?
          return "スレッド内にメッセージが見つかりませんでした。"
        end

        format_thread_messages(messages, starter_message)
      rescue => e
        Rails.logger.error "GetThreadContext failed: #{e.class} - #{e.message}"
        "スレッド履歴の取得中にエラーが発生しました: #{e.message}"
      end

      private

      # Discord APIのエラーレスポンスを解析してわかりやすいメッセージに変換
      # @param response [HTTP::Response] Discord APIのレスポンス
      # @param thread_id [String] スレッドID
      # @return [String] エラーメッセージ
      def parse_discord_error(response, thread_id)
        begin
          error_data = JSON.parse(response.body)
          error_code = error_data["code"]
          error_message = error_data["message"]

          case error_code
          when 10003 # Unknown Channel
            "スレッドID「#{thread_id}」が見つかりませんでした。スレッドが削除されたか、アクセス権限がない可能性があります。"
          when 50001 # Missing Access
            "スレッドID「#{thread_id}」へのアクセス権限がありません。"
          when 50013 # Missing Permissions
            "スレッドID「#{thread_id}」の閲覧権限がありません。"
          else
            "スレッドID「#{thread_id}」のメッセージ取得に失敗しました。(エラーコード: #{error_code}, メッセージ: #{error_message})"
          end
        rescue JSON::ParserError
          "スレッドID「#{thread_id}」のメッセージ取得に失敗しました。(HTTPステータス: #{response.status})"
        end
      end

      # メッセージを読みやすい形式にフォーマット
      # @param messages [Array<Hash>] メッセージの配列（新しい順）
      # @param starter_message [Hash, nil] 親チャンネルから取得した起点メッセージ
      # @return [String] フォーマットされた会話履歴
      def format_thread_messages(messages, starter_message = nil)
        all_messages = []

        # 起点メッセージを最初に追加
        if starter_message
          all_messages << starter_message
        end

        # スレッド内のメッセージを追加（古い順）
        all_messages.concat(messages.reverse)

        formatted = all_messages.map.with_index do |msg, index|
          # ユーザー表示名
          author_name = Discord::Formatter.bold_display_name(msg["author"])

          content = msg["content"] || "(コンテンツなし)"
          timestamp = Time.parse(msg["timestamp"]).strftime("%Y-%m-%d %H:%M") rescue "不明な日時"

          # 添付ファイルがある場合は内容も取得
          attachments_text = format_attachments(msg["attachments"])

          # 最初のメッセージ(起点メッセージ)を強調
          if index == 0
            message_text = "📌 【起点メッセージ】\n#{timestamp} | #{author_name}\n#{content}"
          else
            message_text = "#{timestamp} | #{author_name}\n#{content}"
          end

          message_text += "\n\n#{attachments_text}" if attachments_text.present?
          message_text
        end.join("\n\n---\n\n")

        "【スレッド会話履歴】（全#{all_messages.size}件）\n\n#{formatted}"
      end

      # 添付ファイルをフォーマット
      # @param attachments [Array<Hash>, nil] 添付ファイルの配列
      # @return [String, nil] フォーマットされた添付ファイル情報
      def format_attachments(attachments)
        return nil if attachments.blank?

        attachments.map do |attachment|
          filename = attachment["filename"]
          url = attachment["url"]
          content_type = attachment["content_type"]
          size = attachment["size"]

          # テキストファイルの場合は内容をダウンロード
          if content_type&.start_with?("text/")
            content = Discord::AttachmentDownloader.download_text_content(url, filename: filename)
            if content
              "【添付ファイル: #{filename}】\n```\n#{content}\n```"
            else
              "【添付ファイル: #{filename} (#{size} bytes)】\nURL: #{url}"
            end
          else
            "【添付ファイル: #{filename} (#{content_type}, #{size} bytes)】\nURL: #{url}"
          end
        end.join("\n\n")
      end

    end
  end
end

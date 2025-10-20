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
      def format_thread_messages(messages)
        # 古い順に並び替え（会話の流れが自然になる）
        sorted_messages = messages.reverse

        formatted = sorted_messages.map do |msg|
          # ユーザー表示名
          author_name = Discord::Formatter.bold_display_name(msg["author"])

          content = msg["content"] || "(コンテンツなし)"
          timestamp = Time.parse(msg["timestamp"]).strftime("%Y-%m-%d %H:%M") rescue "不明な日時"

          # 添付ファイルがある場合は内容も取得
          attachments_text = format_attachments(msg["attachments"])

          message_text = "#{timestamp} | #{author_name}\n#{content}"
          message_text += "\n\n#{attachments_text}" if attachments_text.present?
          message_text
        end.join("\n\n---\n\n")

        "【スレッド会話履歴】（全#{sorted_messages.size}件）\n\n#{formatted}"
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
            content = download_text_file(url)
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

      # テキストファイルの内容をダウンロード
      # @param url [String] ファイルのURL
      # @return [String, nil] ファイルの内容（失敗時はnil）
      def download_text_file(url)
        require 'net/http'
        require 'uri'

        uri = URI.parse(url)
        response = Net::HTTP.get_response(uri)

        if response.is_a?(Net::HTTPSuccess)
          # バイナリデータを強制的にUTF-8として解釈
          content = response.body.force_encoding('UTF-8')

          # サイズが大きすぎる場合は先頭部分のみ返す
          if content.bytesize > 10000
            "#{content[0..10000]}\n\n... (#{content.bytesize} bytes中10000 bytesまで表示)"
          else
            content
          end
        else
          Rails.logger.error "Failed to download attachment: #{response.code} #{response.message}"
          nil
        end
      rescue => e
        Rails.logger.error "Error downloading attachment: #{e.class} - #{e.message}"
        nil
      end
    end
  end
end

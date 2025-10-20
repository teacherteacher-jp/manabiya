module Discord
  module Formatter
    # ユーザーIDをメンション形式に変換
    # @param user_id [String] ユーザーID
    # @return [String] <@USER_ID> 形式
    def self.mention_user(user_id)
      "<@#{user_id}>"
    end

    # チャンネルIDをメンション形式に変換
    # @param channel_id [String] チャンネルID
    # @return [String] <#CHANNEL_ID> 形式
    def self.mention_channel(channel_id)
      "<##{channel_id}>"
    end

    # メッセージへの直接リンクを生成
    # @param server_id [String] サーバーID
    # @param channel_id [String] チャンネルID
    # @param message_id [String] メッセージID
    # @return [String] Discord メッセージURL
    def self.message_link(server_id:, channel_id:, message_id:)
      "https://discord.com/channels/#{server_id}/#{channel_id}/#{message_id}"
    end

    # ユーザー情報から表示名を取得
    # @param author [Hash] author情報（username, global_name含む）
    # @return [String] 表示名
    def self.display_name(author)
      return "不明なユーザー" unless author

      # global_name（表示名）を優先、なければusername
      author["global_name"] || author["username"] || "不明なユーザー"
    end

    # ユーザー情報から太字の表示名を取得
    # @param author [Hash] author情報（username, global_name含む）
    # @return [String] 太字の表示名
    def self.bold_display_name(author)
      name = display_name(author)
      "**#{name}**"
    end

    # メッセージ情報を整形（ユーザー表示名 + チャンネルリンク付き）
    # @param message [Hash] メッセージ情報
    # @param server_id [String] サーバーID
    # @param options [Hash] オプション
    # @option options [Boolean] :include_link メッセージリンクを含めるか
    # @option options [Boolean] :include_channel チャンネル情報を含めるか
    # @return [String] 整形されたメッセージ情報
    def self.format_message_info(message, server_id:, include_link: true, include_channel: true)
      parts = []

      # ユーザー情報
      parts << bold_display_name(message["author"])

      # チャンネル情報
      if include_channel && message["channel_id"]
        parts << "in #{mention_channel(message['channel_id'])}"
      end

      # タイムスタンプ
      if message["timestamp"]
        timestamp = Time.parse(message["timestamp"]).strftime("%Y-%m-%d %H:%M") rescue nil
        parts << "(#{timestamp})" if timestamp
      end

      result = parts.join(" ")

      # メッセージリンク
      if include_link && message["id"] && message["channel_id"]
        link = message_link(
          server_id: server_id,
          channel_id: message["channel_id"],
          message_id: message["id"]
        )
        result += "\n#{link}"
      end

      result
    end
  end
end

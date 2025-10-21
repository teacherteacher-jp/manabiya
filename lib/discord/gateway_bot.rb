module Discord
  class GatewayBot
    def initialize(token)
      @bot = Discordrb::Bot.new(token: token)
      setup_handlers
    end

    def setup_handlers
      # 自動応答対象チャンネルのIDを取得
      auto_response_channel_ids = [
        Rails.application.credentials.dig(:discord, :community_help_channel_id)
      ].compact.map(&:to_s)

      # メンション検知
      @bot.mention do |event|
        # リプライの場合、本文に明示的なメンションが含まれているかチェック
        if reply_without_explicit_mention?(event)
          Rails.logger.info "Skipping reply without explicit mention from #{event.user.name}"
          next
        end

        handle_message(event, mentioned: true)
      end

      # メッセージ検知（自動応答チャンネル用）
      @bot.message do |event|
        # ボット自身のメッセージは無視
        next if event.user.bot_account?

        # 自動応答対象チャンネルかチェック
        channel_id = event.channel.thread? ? event.channel.parent_id : event.channel.id
        next unless auto_response_channel_ids.include?(channel_id.to_s)

        # 自動応答対象チャンネルでもスレッドであればスキップ
        next if event.channel.thread?

        # メンションは別ハンドラで処理するのでスキップ
        next if event.message.mentions.any? { |mention| mention.id == @bot.profile.id }

        handle_message(event, mentioned: false)
      end

      # 起動完了のログ
      @bot.ready do |event|
        Rails.logger.info "Discord Gateway Bot is ready!"
        Rails.logger.info "Logged in as: #{event.bot.profile.username}"
      end
    end

    def handle_message(event, mentioned:)
      Rails.logger.info "Message detected from #{event.user.name}: #{event.message.content} (mentioned: #{mentioned})"

      # メンション部分を削除して実際のメッセージを取得
      content = event.message.content.gsub(/<@!?\d+>/, "").strip

      # 添付ファイル情報を取得
      attachments_info = event.message.attachments.map do |attachment|
        {
          id: attachment.id.to_s,
          filename: attachment.filename,
          size: attachment.size,
          url: attachment.url,
          proxy_url: attachment.proxy_url
        }
      end

      # スレッドIDを取得または作成
      thread_id = if event.channel.thread?
        # すでにスレッド内でのメッセージ
        Rails.logger.info "Responding in existing thread: #{event.channel.id}"
        event.channel.id
      else
        # チャンネルでのメッセージ: 新しいスレッドを作成
        Rails.logger.info "Creating new thread in channel: #{event.channel.id}"
        thread = event.channel.start_thread(
          "#{event.user.name}さんとの会話",
          4320, # 3日後にInactiveになる
          message: event.message
        )
        thread.id
      end

      # 即座に「考え中」を示すリアクションを追加
      event.message.react("🐝")

      # ジョブキューに投げて非同期処理
      DiscordLlmResponseJob.perform_later(
        channel_id: event.channel.id.to_s,
        thread_id: thread_id.to_s,
        user_message: content.presence || "こんにちは",
        user_name: event.user.name,
        attachments: attachments_info
      )

      Rails.logger.info "Enqueued DiscordLlmResponseJob for thread: #{thread_id} (#{attachments_info.size} attachments)"
    rescue => e
      Rails.logger.error "Error in message handler: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      begin
        event.respond "エラーが発生しました。しばらく待ってから再度お試しください。"
      rescue => response_error
        Rails.logger.error "Failed to send error message: #{response_error.message}"
      end
    end

    def run
      Rails.logger.info "Starting Discord Gateway Bot..."
      @bot.run
    end

    private

    # リプライで、かつ本文に明示的なメンションが含まれていない場合にtrueを返す
    def reply_without_explicit_mention?(event)
      message = event.message
      return false unless message

      # リプライかどうかをチェック(referenced_messageが存在すればリプライ)
      return false unless message.referenced_message.present?

      # 本文にボットへのメンションが含まれているかチェック
      bot_id = @bot.profile&.id
      return false unless bot_id

      content = message.content.to_s
      has_explicit_mention = content.include?("<@#{bot_id}>") || content.include?("<@!#{bot_id}>")

      # リプライで、かつ明示的なメンションがない場合にtrue
      !has_explicit_mention
    end
  end
end

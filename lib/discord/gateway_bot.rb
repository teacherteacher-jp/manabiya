module Discord
  class GatewayBot
    def initialize(token)
      @bot = Discordrb::Bot.new(token: token)
      setup_handlers
    end

    def setup_handlers
      # メンション検知
      @bot.mention do |event|
        Rails.logger.info "Mention detected from #{event.user.name}: #{event.message.content}"

        # メンション部分を削除して実際のメッセージを取得
        content = event.message.content.gsub(/<@!?\d+>/, "").strip

        # スレッドIDを取得または作成
        thread_id = if event.channel.thread?
          # すでにスレッド内でのメンション
          Rails.logger.info "Responding in existing thread: #{event.channel.id}"
          event.channel.id
        else
          # チャンネルでのメンション: 新しいスレッドを作成
          Rails.logger.info "Creating new thread in channel: #{event.channel.id}"
          thread = event.channel.start_thread(
            "#{event.user.name}さんとの会話",
            4320, # 3日後にInactiveになる
            message: event.message
          )
          thread.id
        end

        # 即座に「考え中」を示すリアクションを追加
        event.message.react("👌")

        # ジョブキューに投げて非同期処理
        DiscordLlmResponseJob.perform_later(
          channel_id: event.channel.id.to_s,
          thread_id: thread_id.to_s,
          user_message: content.presence || "こんにちは",
          user_name: event.user.name
        )

        Rails.logger.info "Enqueued DiscordLlmResponseJob for thread: #{thread_id}"
      rescue => e
        Rails.logger.error "Error in mention handler: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        begin
          event.respond "エラーが発生しました。しばらく待ってから再度お試しください。"
        rescue => response_error
          Rails.logger.error "Failed to send error message: #{response_error.message}"
        end
      end

      # 起動完了のログ
      @bot.ready do |event|
        Rails.logger.info "Discord Gateway Bot is ready!"
        Rails.logger.info "Logged in as: #{event.bot.profile.username}"
      end
    end

    def run
      Rails.logger.info "Starting Discord Gateway Bot..."
      @bot.run
    end
  end
end

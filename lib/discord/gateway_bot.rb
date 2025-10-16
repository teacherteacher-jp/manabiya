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

        # オウム返し
        response = if content.empty?
          "こんにちは!何か質問はありますか?"
        else
          content
        end

        # スレッドかチャンネルかを判定
        if event.channel.thread?
          # スレッド内でのメンション: そのスレッド内で返信
          Rails.logger.info "Responding in thread: #{event.channel.id}"
          event.respond response
        else
          # チャンネルでのメンション: 新しいスレッドを作成して返信
          Rails.logger.info "Creating thread in channel: #{event.channel.id}"
          thread = event.channel.start_thread(
            "#{event.user.name}さんとの会話",
            4320, # 3日後にInactiveになる
            message: event.message
          )
          thread.send_message(response)
        end
      rescue => e
        Rails.logger.error "Error in mention handler: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        event.respond "エラーが発生しました。しばらく待ってから再度お試しください。"
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

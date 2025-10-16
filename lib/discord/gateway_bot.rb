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

        event.respond response
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

class InvitationWatcherJob < ApplicationJob
  queue_as :default

  def perform
    bot = Discord::Bot.new(Rails.application.credentials.dig("discord_app", "bot_token_super"))
    invitations = bot.invitations.sort_by { _1["created_at"] }
    thread_id = Rails.application.credentials.dig("discord", "admin_thread_id")

    invitations.each_slice(50).each do |sub_invitations|
      message =
        "```" +
        ["created", "expires", "code", "uses", "inviter"].map { _1.ljust(10) }.join("\t") + "\n" +
        sub_invitations.map { |inv|
          expires_at = inv.dig("expires_at")
          [
            inv.dig("created_at").first(10),
            expires_at ? expires_at.first(10) : "----------",
            inv.dig("code"),
            inv.dig("uses").to_s,
            inv.dig("inviter", "global_name"),
          ].map { _1.ljust(10) }.join("\t")
        }.join("\n") +
        "```"

      pp bot.send_message(channel_or_thread_id: thread_id, content: message)
    end
  end
end

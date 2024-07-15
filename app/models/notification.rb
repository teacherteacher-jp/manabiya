class Notification
  def initialize
    @bot = Discord::Bot.new(Rails.application.credentials.dig("discord_app", "bot_token"))
    @thread_id = Rails.application.credentials.dig("discord", "thread_id")
  end

  def notify_schedules(schedules)
    date = schedules.first.date
    with_assignments, without_assignments = schedules.partition(&:assignment)

    fields = [{
      name: "お願いするみなさんです！当日9:00からよろしくです",
      value: with_assignments.map { "<@!#{_1.member.discord_uid}>" }.join(" "),
    }]
    fields.push({
      name: "こちらの人々は、また別の機会にお願いします！",
      value: without_assignments.map { "<@!#{_1.member.discord_uid}>" }.join(" "),
    }) if without_assignments.count > 0

    embeds = [{
      title: ":date: %d/%d(%s)のボランティアの担当をお知らせ :date:" % [date.month, date.day, %w[日 月 火 水 木 金 土][date.wday]],
      url: "https://bit.ly/tt-manabiya",
      fields: fields,
    }]

    pp @bot.send_message(channel_or_thread_id: @thread_id, embeds:)
  end
end
class Notification
  def initialize
    @bot = Discord::Bot.new(Rails.application.credentials.dig("discord_app", "bot_token"))
    @thread_id = Rails.application.credentials.dig("discord", "thread_id")
  end

  def notify_schedules(schedules)
    date = schedules.first.date
    with_assignments = schedules.select(&:assignment)

    fields =
      with_assignments.group_by(&:slot).sort_by { _1 }.to_h.map do |slot, schedules_in_slot|
        {
          name: Schedule.slot_name_of(slot),
          value: schedules_in_slot.map { "<@!#{_1.member.discord_uid}>" }.join(" "),
        }
      end

    embeds = [{
      title: ":date: %d/%d(%s)のボランティアの担当をお知らせ :date:" % [date.month, date.day, %w[日 月 火 水 木 金 土][date.wday]],
      description: "定刻になりましたら会場にお入りください！\n :school: [MetaLife会場](%s) ┃ :memo: [案内ドキュメント](%s)" % [
        ENV["SCHOOL_URL"], ENV["SCHOOL_DOCUMENT_URL"]
      ],
      fields: fields,
    }]

    content = schedules.map { _1.member.discord_uid }.uniq.map { "<@!#{_1}>" }.join(" ")
    allowed_mentions = {
      parse: ["users"]
    }

    pp @bot.send_message(channel_or_thread_id: @thread_id, content:, embeds:, allowed_mentions:)
  end
end

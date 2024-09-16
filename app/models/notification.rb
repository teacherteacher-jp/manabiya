class Notification
  def initialize
    @bot = Discord::Bot.new(Rails.application.credentials.dig("discord_app", "bot_token"))
  end

  def notify_schedules(schedules)
    thread_id = Rails.application.credentials.dig("discord", "school_thread_id")
    date = schedules.first.date
    with_assignments = schedules.select(&:assignment)

    fields =
      with_assignments.group_by(&:slot).sort_by { _1 }.to_h.map do |slot, schedules_in_slot|
        {
          name: "%s : %s" % [Schedule.time_of(slot), Schedule.name_of(slot)],
          value: schedules_in_slot.map { "<@!#{_1.member.discord_uid}>" }.join(" "),
        }
      end

    description = "定刻になりましたら会場にお入りください！\n"
    description += ":school: [MetaLife会場](%s) | :memo: [案内ドキュメント](%s) | :calendar: [スケジュール入力](%s)" % [
      ENV["SCHOOL_URL"], ENV["SCHOOL_DOCUMENT_URL"], Rails.application.credentials.base_url + "/my/schedules"
    ]
    embeds = [{
      title: "%d/%d(%s)のボランティアの担当をお知らせ" % [date.month, date.day, %w[日 月 火 水 木 金 土][date.wday]],
      description: description,
      fields: fields,
    }]

    content = schedules.map { _1.member.discord_uid }.uniq.map { "<@!#{_1}>" }.join(" ")
    allowed_mentions = {
      parse: ["users"]
    }

    pp @bot.send_message(channel_or_thread_id: thread_id, content:, embeds:, allowed_mentions:)
  end

  def notify_call_for_scheduling
    thread_id = Rails.application.credentials.dig("discord", "school_thread_id")

    content = "スケジュール入力、お待ちしています！\n"
    content += ":calendar: [スケジュールを入力する](%s) :calendar:" % [Rails.application.credentials.base_url + "/my/schedules"]

    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end
end

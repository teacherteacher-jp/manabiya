class Notification
  include ApplicationHelper

  THREAD_TYPES = {
    school_general: "school_general_thread_id",
    school_contact: "school_contact_thread_id",
    profile: "profile_thread_id",
    event: "event_thread_id"
  }.freeze

  def initialize
    @bot = Discord::Bot.new(Rails.application.credentials.dig("discord_app", "bot_token"))
  end

  def thread_id_for(type)
    Rails.application.credentials.dig("discord", THREAD_TYPES[type])
  end

  def notify_student_created(student)
    thread_id = thread_id_for(:school_general)
    content = "#{student.grade}の生徒さんが登録されました！\n%s" % [
      Rails.application.credentials.base_url + "/students/#{student.id}"
    ]
    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_student_updated(student)
    thread_id = thread_id_for(:school_general)
    content = "#{student.grade}の生徒さんの情報が更新されました！\n%s" % [
      Rails.application.credentials.base_url + "/students/#{student.id}"
    ]
    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_student_memo_created(student_memo)
    thread_id = thread_id_for(:school_general)
    content = "<@!#{student_memo.member.discord_uid}> さんが #{student_memo.student.grade}の生徒さんついてのメモを投稿しました！"
    link = Rails.application.credentials.base_url + "/students/#{student_memo.student.id}"
    embeds = [{
      description: [student_memo.content, link].join("\n\n"),
      author: { name: student_memo.category, icon_url: student_memo.member.icon_url },
    }]
    pp @bot.send_message(channel_or_thread_id: thread_id, content:, embeds:)
  end

  def notify_member_schedule_input(member:, dates:)
    thread_id = thread_id_for(:school_contact)
    full_date = dates.sort.uniq.map { mdw(_1.to_date) }.join(", ")

    @bot.send_message(
      channel_or_thread_id: thread_id,
      content: "<@!#{member.discord_uid}> さんが #{full_date} のスケジュールを入力しました！"
    )
  end

  def notify_schedules(schedules)
    thread_id = thread_id_for(:school_contact)
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
    thread_id = thread_id_for(:school_contact)

    content = "スケジュール入力、お待ちしています！\n"
    content += ":calendar: [スケジュールを入力する](%s) :calendar:" % [Rails.application.credentials.base_url + "/my/schedules"]

    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_school_stats
    thread_id = thread_id_for(:school_contact)

    content = [
      "実状把握のため、参加される方はManabiyaからスケジュール登録してもらえるとうれしいです :dizzy:",
      "データが実態と合っていない場合は修正してください :pray:",
      Rails.application.credentials.base_url
    ].join("\n")
    embeds = [school_stats_today, school_stats_30days]

    pp @bot.send_message(channel_or_thread_id: thread_id, content:, embeds:)
  end

  def school_stats_today
    schedules = Schedule.joins(:assignment).where("schedules.date = ?", Date.today)
    title = "今日のコンボラ参加は %d人 %d件 でした" % [schedules.pluck(:member_id).uniq.count, schedules.count]
    fields =
      schedules.group_by(&:slot).sort_by { _1 }.to_h.map { |slot, schedules_in_slot|
        {
          name: "%s : %s" % [Schedule.time_of(slot), Schedule.name_of(slot)],
          value: schedules_in_slot.map { "<@!#{_1.member.discord_uid}>" }.join(" "),
        }
      }
    { title:, fields: }
  end

  def school_stats_30days
    schedules = Schedule.joins(:assignment).where("schedules.date >= ?", 30.days.ago.to_date)
    title = "過去30日間のコンボラ参加は %d人 %d件 です" % [schedules.pluck(:member_id).uniq.count, schedules.count]
    description = schedules.
                  group(:member).count.sort_by { _2 }.reverse.
                  map { |m, c| "<@!%s> %d件" % [m.discord_uid, c] }.join(" / ")
    { title:, description:, }
  end

  def notify_member_region_created(member_region)
    thread_id = thread_id_for(:profile)
    region_with_category = "「%s」(%s)" % [member_region.region.name, member_region.category]

    content = "<@!#{member_region.member.discord_uid}> さんが#{region_with_category}を登録しました！\n%s" % [
      Rails.application.credentials.base_url + "/members/#{member_region.member_id}"
    ]
    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_family_member_created(family_member)
    thread_id = thread_id_for(:profile)

    content = "<@!#{family_member.member.discord_uid}> さんが「%s」を登録しました！\n%s" % [
      family_member.relationship_in_japanese,
      Rails.application.credentials.base_url + "/members/#{family_member.member_id}"
    ]
    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_event(event:, content:)
    thread_id = thread_id_for(:event)
    embeds = [event.to_embed]
    pp @bot.send_message(channel_or_thread_id: thread_id, content:, embeds:)
  end

  def notify_events(events:, content:)
    return if events.empty?

    thread_id = thread_id_for(:event)
    embeds = events.map(&:to_embed)
    pp @bot.send_message(channel_or_thread_id: thread_id, content:, embeds:)
  end
end

class Notification
  include ApplicationHelper

  THREAD_TYPES = {
    event: "event_thread_id",
    profile: "profile_thread_id",
    school_contact: "school_contact_thread_id",
    school_general: "school_general_thread_id",
    school_report: "admin_school_thread_id",
    admin: "admin_thread_id",
    intake: "intake_thread_id",
  }.freeze

  def initialize
    @bot = Discord::Bot.new(Rails.application.credentials.dig("discord_app", "bot_token"))
  end

  def thread_id_for(type)
    Rails.application.credentials.dig("discord", THREAD_TYPES[type])
  end

  def app_base_url
    Rails.application.credentials.base_url
  end

  def notify_student_created(student)
    thread_id = thread_id_for(:school_report)
    content = "#{student.grade}の生徒さんが登録されました！"
    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_student_updated(student)
    thread_id = thread_id_for(:school_report)
    content = "#{student.grade}の生徒さんの情報が更新されました！"
    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_school_memo_created(school_memo)
    thread_id = thread_id_for(:school_report)
    content = "<@!#{school_memo.member.discord_uid}> さんがメモを投稿しました！"

    if school_memo.students.count > 0
      students = school_memo.students.map { |student|
        student_string = student.grade
        if student.guardians.any? && school_memo.category != "家庭から"
          guardian_mentions = student.guardians.map { |g| "<@!#{g.discord_uid}>" }.join(" ")
          student_string += "(保護者 #{guardian_mentions})"
        end
        student_string
      }.join("、")
      content += "\n関連する生徒: #{students}"
    end

    embeds = [{
      author: { name: school_memo.category, icon_url: school_memo.member.icon_url },
      title: ymdw(school_memo.date),
      description: school_memo.content,
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
      ENV["SCHOOL_URL"], ENV["SCHOOL_DOCUMENT_URL"], app_base_url + "/my/schedules"
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
    content += ":calendar: [スケジュールを入力する](%s) :calendar:" % [app_base_url + "/my/schedules"]

    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_school_stats
    thread_id = thread_id_for(:school_contact)
    schedules = Schedule.joins(:assignment).where("schedules.date = ?", Date.today)

    content = [
      "実状把握のため、参加される方はManabiyaからスケジュール登録してもらえるとうれしいです :dizzy:",
      "データが実態と合っていない場合は修正してください :pray:",
      app_base_url + "/my/schedules",
      "",
      schedules.map { _1.member }.uniq.map { "<@#{_1.discord_uid}>" }.join(" "),
      "よかったら今日の様子を下記フォームからご共有ください :relaxed:",
      app_base_url + "/school_memos/new"
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

  def notify_assignment_created(assignment)
    thread_id = thread_id_for(:school_contact)
    schedule = assignment.schedule
    embeds = [{
      title: ":white_check_mark: 参加登録されました",
      description: [mdw(schedule.date), Schedule.name_of(schedule.slot), Schedule.time_of(schedule.slot)].join(" ") + " | <@!#{schedule.member.discord_uid}>さん"
    }]
    pp @bot.send_message(channel_or_thread_id: thread_id, embeds:)
  end

  def notify_member_region_created(member_region)
    thread_id = thread_id_for(:profile)
    region_with_category = "「%s」(%s)" % [member_region.region.name, member_region.category]

    content = "<@!#{member_region.member.discord_uid}> さんが#{region_with_category}を登録しました！\n%s" % [
      app_base_url + "/members/#{member_region.member_id}"
    ]
    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_family_member_created(family_member)
    thread_id = thread_id_for(:profile)

    content = "<@!#{family_member.member.discord_uid}> さんが「%s」を登録しました！\n%s" % [
      family_member.relationship_in_japanese,
      app_base_url + "/members/#{family_member.member_id}"
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

  def notify_metalife_user_created(metalife_user)
    thread_id = thread_id_for(:school_report)
    content = "新しいMetaLifeユーザーが検出されました\n" \
              "ID: #{metalife_user.metalife_id}\n" \
              "名前: #{metalife_user.name}\n" \
              "#{app_base_url}/metalife_users"

    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_metalife_user_school_entered(metalife_user)
    linkable = metalife_user.linkable
    return unless linkable
    return unless linkable.is_a?(Member)

    thread_id = thread_id_for(:school_contact)
    content = "<@!#{linkable.discord_uid}> さんがコンコンのスペースに入室しました"
    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end

  def notify_intake_response_recorded(intake_response)
    thread_id = thread_id_for(:intake)
    session = intake_response.intake_session
    member = session.member
    intake = session.intake

    total = intake.intake_items.count
    recorded = session.intake_responses.count

    embeds = [{
      color: 0xF59E0B,
      author: { name: member.name, icon_url: member.icon_url },
      title: intake.title,
      description: "項目「#{intake_response.intake_item.name}」の回答が記録されました",
      footer: { text: "#{recorded} / #{total} 項目完了" }
    }]
    pp @bot.send_message(channel_or_thread_id: thread_id, embeds:)
  end

  def notify_intake_report_created(intake_report)
    thread_id = thread_id_for(:intake)
    session = intake_report.intake_session
    member = session.member
    intake = session.intake

    embeds = [{
      color: 0x10B981,
      author: { name: member.name, icon_url: member.icon_url },
      title: "#{intake.title} のレポートが作成されました",
      description: intake_report.content.truncate(200),
      url: "#{app_base_url}/intake_reports/#{intake_report.id}"
    }]
    pp @bot.send_message(channel_or_thread_id: thread_id, embeds:)
  end

  def notify_unlinked_metalife_users(unlinked_users, target_date)
    thread_id = thread_id_for(:school_report)

    # ユーザーごとの最終入室時刻を取得
    user_entries = unlinked_users.map do |user|
      last_entry = user.metalife_events
        .where(event_type: 'enter')
        .where(occurred_at: target_date.all_day)
        .order(occurred_at: :desc)
        .first

      last_entry_time = last_entry&.occurred_at&.in_time_zone('Tokyo')&.strftime('%H:%M') || '不明'

      "- #{user.name} (ID: #{user.metalife_id}) - 最終入室: #{last_entry_time}"
    end

    content = [
      "#{mdw(target_date)}に入室が確認されましたが、Member/Studentと紐付いていないユーザーが#{unlinked_users.count}件見つかりました :mag:",
      "",
      user_entries.join("\n"),
      "",
      "誰が誰なのかわかる場合は、管理画面で紐付け作業を行ってください :pray:",
      "#{app_base_url}/metalife_users"
    ].join("\n")

    pp @bot.send_message(channel_or_thread_id: thread_id, content:)
  end
end

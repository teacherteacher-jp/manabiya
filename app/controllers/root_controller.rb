class RootController < ApplicationController
  def index
    @school_menu_items = [
      { text: "ボランティアのスケジュール入力", path: my_schedules_path },
      { text: "ボランティアのスケジュール確認", path: schedules_path },
    ]
    if current_member.can_access_student_info?
      [
        { text: "生徒さんたちの情報", path: students_path },
        { text: "スクールに関するメモ", path: school_memos_path },
      ].each { |item| @school_menu_items << item }
    end

    @community_menu_items = [
      { text: "わたしのプロフィール", path: member_path(current_member) },
      { text: "みんなのゆかりの地", path: regions_path },
      { text: "みんなの参加時期", path: generations_path },
    ]

    @recent_events = Event.in_future.order(start_at: :asc).limit(3)
  end
end

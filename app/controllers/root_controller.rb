class RootController < ApplicationController
  def index
    @school_menu_items = [
      { text: "ボランティアのスケジュールを入力する", path: my_schedules_path },
      { text: "ボランティアのスケジュールを確認する", path: schedules_path },
    ]
    if current_member.can_access_student_info?
      [
        { text: "生徒さんたちの情報を確認する", path: students_path },
        { text: "スクールに関するメモを書く", path: school_memos_path },
      ].each { |item| @school_menu_items << item }
    end
    if current_member.children_as_students.count > 0
      @school_menu_items << { text: "家庭からのメモを書く", path: new_school_memo_path(student_ids: current_member.children_as_students.pluck(:id).map(&:to_s).join(",")) }
    end

    @community_menu_items = [
      { text: "自分のプロフィールを見る", path: member_path(current_member) },
      { text: "みんなのゆかりの地を見る", path: regions_path },
      { text: "みんなの参加時期を見る", path: generations_path },
    ]

    @recent_events = Event.in_future.order(start_at: :asc).limit(3)
    @vacation_period = Oyasumi.current_vacation_period
  end
end

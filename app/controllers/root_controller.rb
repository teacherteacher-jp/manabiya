class RootController < ApplicationController
  def index
    @menu_items = [
      { text: "生徒さんたちの情報", path: students_path },
      { text: "わたしのスケジュール", path: my_schedules_path },
      { text: "みんなのスケジュール", path: schedules_path },
      { text: "わたしのプロフィール", path: member_path(current_member) },
      { text: "みんなのゆかりの地", path: regions_path },
      { text: "みんなの参加時期", path: generations_path },
    ]

    @recent_events = Event.in_future.order(start_at: :asc).limit(3)
  end
end

class RootController < ApplicationController
  def index
    @menu_items = [
      { text: "わたしのプロフィール", path: member_path(current_member) },
      { text: "わたしのスケジュール", path: my_schedules_path },
      { text: "みんなのゆかりの地", path: regions_path },
      { text: "みんなの参加時期", path: generations_path },
    ]

    @admin_menu_items = [
      { text: "みんなのスケジュール", path: schedules_path },
    ]
  end
end

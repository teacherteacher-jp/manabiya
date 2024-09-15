class RootController < ApplicationController
  def index
    @menu_items = [
      { text: "わたしのスケジュール", path: me_path },
      { text: "みんなのスケジュール", path: schedules_path },
      { text: "みんなの居住地", path: regions_path },
    ]
  end
end

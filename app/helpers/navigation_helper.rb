module NavigationHelper
  def sidebar_nav_items
    items = [
      { label: "ホーム", path: root_path, icon: "home" },
      { label: "スケジュール", path: my_schedules_path, icon: "calendar" },
    ]

    if current_member.can_access_student_info?
      items << { label: "生徒", path: students_path, icon: "users" }
    end

    items + [
      { label: "イベント", path: events_path, icon: "calendar-days" },
      { label: "問診", path: intakes_path, icon: "clipboard-document-list" },
      { label: "ゆかりの地", path: regions_path, icon: "map-pin" },
    ]
  end

  def bottom_nav_items
    [
      { label: "ホーム", path: root_path, icon: "home" },
      { label: "スケジュール", path: my_schedules_path, icon: "calendar" },
      { label: "イベント", path: events_path, icon: "calendar-days" },
      { label: "問診", path: intakes_path, icon: "clipboard-document-list" },
      { label: "マイページ", path: member_path(current_member), icon: "user" },
    ]
  end

  def current_nav_item?(path)
    # root_pathは完全一致、それ以外は前方一致
    if path == root_path
      request.path == root_path
    else
      request.path.start_with?(path)
    end
  end
end

module NavigationHelper
  def sidebar_nav_sections
    sections = []

    # スクール
    school_items = [
      { label: "スケジュール入力", path: my_schedules_path },
      { label: "スケジュール確認", path: schedules_path },
    ]
    if current_member.can_access_student_info?
      school_items << { label: "生徒", path: students_path }
      school_items << { label: "スクールメモ", path: school_memos_path }
    end
    if current_member.guarded_students.count > 0
      school_items << {
        label: "家庭からのメモ",
        path: new_school_memo_path(student_ids: current_member.guarded_students.pluck(:id).join(",")),
      }
    end
    sections << { title: "スクール", items: school_items }

    # イベント
    sections << { title: "イベント", items: [
      { label: "イベント一覧", path: events_path },
    ] }

    # 問診
    sections << { title: "問診", items: [
      { label: "問診一覧", path: intakes_path },
      { label: "問診レポート", path: my_intake_reports_path },
    ] }

    # コミュニティ
    sections << { title: "コミュニティ", items: [
      { label: "ゆかりの地", path: regions_path },
      { label: "参加時期", path: generations_path },
    ] }

    sections
  end

  def sidebar_admin_items
    return [] unless current_member.admin?

    [
      { label: "MetaLifeユーザ", path: metalife_users_path },
      { label: "全問診レポート", path: intake_reports_path },
    ]
  end

  def current_nav_item?(path)
    if path == root_path
      request.path == root_path
    else
      request.path.start_with?(path)
    end
  end
end

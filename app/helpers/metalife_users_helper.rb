module MetalifeUsersHelper
  def linkable_options_for(metalife_user)
    return [] unless metalife_user.linkable_type.present?

    case metalife_user.linkable_type
    when "Member"
      Member.order(:name).map { |m| [m.name, m.id] }
    when "Student"
      active = Student.active.order(:name).map { |s| ["#{s.name} (#{s.grade})", s.id] }
      inactive = Student.inactive.order(:name).map { |s| ["#{s.name} (#{s.grade})", s.id] }
      { "利用中" => active, "それ以外" => inactive }
    else
      []
    end
  end

  def linkable_members_json
    Member.order(:name).map { |m| { name: m.name, id: m.id } }
  end

  def linkable_students_json
    active, inactive = Student.order(:name).partition(&:active?)
    format = ->(s) { { name: "#{s.name} (#{s.grade})", id: s.id } }
    { "利用中" => active.map(&format), "それ以外" => inactive.map(&format) }
  end
end

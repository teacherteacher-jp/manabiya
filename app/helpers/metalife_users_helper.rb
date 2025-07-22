module MetalifeUsersHelper
  def linkable_options_for(metalife_user)
    return [] unless metalife_user.linkable_type.present?

    case metalife_user.linkable_type
    when "Member"
      Member.order(:name).map { |m| [m.name, m.id] }
    when "Student"
      Student.order(:name).map { |s| ["#{s.name} (#{s.grade})", s.id] }
    else
      []
    end
  end
end

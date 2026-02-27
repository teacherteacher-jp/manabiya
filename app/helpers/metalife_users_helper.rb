module MetalifeUsersHelper
  def linkable_options_for(metalife_user)
    return [] unless metalife_user.linkable_type.present?

    case metalife_user.linkable_type
    when "Member"
      active, inactive = members_partitioned_by_recent_access
      { "最近のアクセスあり" => active.map { |m| [m.name, m.id] }, "それ以外" => inactive.map { |m| [m.name, m.id] } }
    when "Student"
      active, inactive = Student.order(:name).partition(&:active?)
      format = ->(s) { ["#{s.name} (#{s.grade})", s.id] }
      { "利用中" => active.map(&format), "それ以外" => inactive.map(&format) }
    else
      []
    end
  end

  def linkable_members_json
    active, inactive = members_partitioned_by_recent_access
    format = ->(m) { { name: m.name, id: m.id } }
    { "最近のアクセスあり" => active.map(&format), "それ以外" => inactive.map(&format) }
  end

  def linkable_students_json
    active, inactive = Student.order(:name).partition(&:active?)
    format = ->(s) { { name: "#{s.name} (#{s.grade})", id: s.id } }
    { "利用中" => active.map(&format), "それ以外" => inactive.map(&format) }
  end

  private

  def members_partitioned_by_recent_access
    recent_member_ids = Ahoy::Event.where(time: 2.weeks.ago..).distinct.pluck(:member_id).compact.to_set
    Member.order(:name).partition { |m| recent_member_ids.include?(m.id) }
  end
end

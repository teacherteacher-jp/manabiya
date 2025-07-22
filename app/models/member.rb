class Member < ApplicationRecord
  has_many :schedules, dependent: :destroy
  has_many :assignments, through: :schedules
  has_many :member_regions, dependent: :destroy
  has_many :regions, through: :member_regions
  has_many :family_members, dependent: :destroy
  has_many :children_as_students, foreign_key: :parent_member_id, class_name: "Student"
  has_many :school_memos, dependent: :destroy
  has_one :metalife_user, as: :linkable, dependent: :nullify

  validates :discord_uid, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 32 }
  validates :icon_url, presence: true, length: { maximum: 2083 }

  after_save :fill_server_joined_at

  def fill_server_joined_at
    return if server_joined_at

    bot = Discord::Bot.new(Rails.application.credentials.dig("discord_app", "bot_token"))
    server_member = bot.server_member(discord_uid)

    return unless server_member

    self.update_columns(server_joined_at: server_member.dig("joined_at"))
  end

  def generation
    return nil unless server_joined_at

    base_date = Date.new(2023, 12, 1)
    return 1 if server_joined_at.to_date < base_date

    joined_date = server_joined_at.to_date
    months_difference = (joined_date.year * 12 + joined_date.month) - (base_date.year * 12 + base_date.month)
    months_difference + 1
  end

  def can_access_student_info?
    return true if admin?
    return true if children_as_students.exists?

    recent_assignments_exist =
      Schedule.joins(:assignment).
        where(member_id: id).
        where(date: (7.days.ago)..(7.days.since)).
        exists?

    return true if recent_assignments_exist

    false
  end

  def can_edit?(school_memo)
    admin? || school_memo.member == self
  end
end

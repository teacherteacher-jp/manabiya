class Student < ApplicationRecord
  has_many :guardianships, dependent: :destroy
  has_many :guardians, through: :guardianships, source: :member
  has_many :school_memo_students, dependent: :destroy
  has_many :school_memos, through: :school_memo_students
  has_one :metalife_user, as: :linkable, dependent: :nullify

  validates :name, presence: true, length: { maximum: 20 }
  validates :grade, presence: true

  after_create_commit :notify_created
  after_update_commit :notify_updated

  enum :grade, {
    小学校1年生: 0,
    小学校2年生: 1,
    小学校3年生: 2,
    小学校4年生: 3,
    小学校5年生: 4,
    小学校6年生: 5,
    中学校1年生: 6,
    中学校2年生: 7,
    中学校3年生: 8,
    それ以外:    9
  }

  enum :status, { active: 0, paused: 1, graduated: 2, withdrawn: 3 }

  class << self
    def status_in_japanese
      {
        active: "利用中",
        paused: "休止中",
        graduated: "卒業済み",
        withdrawn: "利用終了"
      }
    end

    def status_options
      statuses.map { [Student.status_in_japanese[_1[0].to_sym], _1[0]] }
    end
  end

  def status_in_japanese
    Student.status_in_japanese[status.to_sym]
  end

  def notify_created
    Notification.new.notify_student_created(self)
  end

  def notify_updated
    Notification.new.notify_student_updated(self)
  end

  def recent_entry_days(limit: 3)
    return [] unless metalife_user

    metalife_user.metalife_events
      .where(event_type: 'enter')
      .where('occurred_at >= ?', Time.zone.now.beginning_of_day - 30.days)
      .order(occurred_at: :desc)
      .group_by { |event| event.occurred_at.in_time_zone('Tokyo').to_date }
      .map { |date, events| { date: date, time: events.min_by(&:occurred_at).occurred_at.in_time_zone('Tokyo') } }
      .first(limit)
  end

  def latest_entry
    return nil unless metalife_user

    event = metalife_user.metalife_events
      .where(event_type: 'enter')
      .order(occurred_at: :desc)
      .first

    return nil unless event

    {
      date: event.occurred_at.in_time_zone('Tokyo').to_date,
      time: event.occurred_at.in_time_zone('Tokyo')
    }
  end

  def recently_entered?(hours: 72)
    return false unless metalife_user

    metalife_user.metalife_events
      .where(event_type: 'enter')
      .where('occurred_at >= ?', hours.hours.ago)
      .exists?
  end
end

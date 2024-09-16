class MemberRegion < ApplicationRecord
  belongs_to :member
  belongs_to :region

  validates :member_id, presence: true
  validates :region_id, presence: true
  validates :category, presence: true

  enum :category, {
    "現在の居住地": 0,
    "かつての居住地": 1,
    "出身地": 2,
  }

  after_create_commit :notify

  def category_short
    case category
    when "現在の居住地"
      "現在"
    when "かつての居住地"
      "かつて"
    when "出身地"
      "出身"
    end
  end

  def notify
    Notification.new.notify_member_region_created(self)
  end
end

class MemberRegion < ApplicationRecord
  belongs_to :member
  belongs_to :region

  validates :member_id, presence: true
  validates :region_id, presence: true
  validates :category, presence: true

  enum category: {
    "現在の居住地": 0,
    "かつての居住地": 1,
    "出身地": 2,
    "その他": 3,
  }
end

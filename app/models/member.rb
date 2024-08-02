class Member < ApplicationRecord
  has_many :schedules, dependent: :destroy
  has_many :assignments, through: :schedules
  has_many :member_regions, dependent: :destroy
  has_many :regions, through: :member_regions

  validates :discord_uid, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 32 }
  validates :icon_url, presence: true, length: { maximum: 2083 }
end

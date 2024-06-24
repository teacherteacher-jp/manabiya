class Member < ApplicationRecord
  validates :discord_uid, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 32 }
  validates :icon_url, presence: true, length: { maximum: 2083 }
end

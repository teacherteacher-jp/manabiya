class Event < ApplicationRecord
  validates :title, presence: true, length: { maximum: 50 }
  validates :description, presence: true, length: { maximum: 200 }
  validates :start_at, presence: true
  validates :venue, presence: true, length: { maximum: 50 }
  validates :source_link, presence: true
end

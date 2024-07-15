class Assignment < ApplicationRecord
  belongs_to :schedule

  validates :schedule_id, presence: true, uniqueness: true
end

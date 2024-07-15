class Assignment < ApplicationRecord
  belongs_to :schedule
  belongs_to :member, through: :schedule

  validates :schedule, presence: true
end

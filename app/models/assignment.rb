class Assignment < ApplicationRecord
  belongs_to :schedule

  validates :schedule_id, presence: true, uniqueness: true

  after_create_commit :notify

  def notify
    Notification.new.notify_assignment_created(self)
  end
end

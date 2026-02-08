class IntakeReport < ApplicationRecord
  belongs_to :intake_session

  after_create { Notification.new.notify_intake_report_created(self) }
end

class IntakeResponse < ApplicationRecord
  belongs_to :intake_session
  belongs_to :intake_item

  after_create { Notification.new.notify_intake_response_recorded(self) }
end

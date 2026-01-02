class IntakeSession < ApplicationRecord
  belongs_to :intake
  belongs_to :member
  has_many :intake_messages, dependent: :destroy
  has_many :intake_responses, dependent: :destroy

  enum :status, { in_progress: 0, completed: 1 }
end

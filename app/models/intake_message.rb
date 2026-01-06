class IntakeMessage < ApplicationRecord
  belongs_to :intake_session

  enum :role, { user: 0, assistant: 1 }

  validates :content, presence: true
end

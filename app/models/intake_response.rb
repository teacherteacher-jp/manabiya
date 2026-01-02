class IntakeResponse < ApplicationRecord
  belongs_to :intake_session
  belongs_to :intake_item
end

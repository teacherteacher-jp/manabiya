class IntakeItem < ApplicationRecord
  belongs_to :intake

  validates :name, presence: true

  default_scope { order(:position) }
end

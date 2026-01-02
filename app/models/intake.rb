class Intake < ApplicationRecord
  has_many :intake_items, dependent: :destroy

  validates :title, presence: true
end

class Intake < ApplicationRecord
  has_many :intake_items, dependent: :destroy
  has_many :intake_sessions, dependent: :destroy

  validates :title, presence: true
end

class Guardianship < ApplicationRecord
  belongs_to :student
  belongs_to :member

  validates :member_id, uniqueness: { scope: :student_id }
end

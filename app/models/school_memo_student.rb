class SchoolMemoStudent < ApplicationRecord
  belongs_to :school_memo
  belongs_to :student

  validates :school_memo_id, uniqueness: { scope: :student_id }
end

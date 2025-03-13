class StudentMemo < ApplicationRecord
  belongs_to :student
  belongs_to :member

  validates :content, presence: true, length: { maximum: 1000 }
  validates :category, presence: true

  enum :category, {
    家庭:         0,
    学校:         1,
    ボランティア: 2
  }
end

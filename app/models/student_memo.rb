class StudentMemo < ApplicationRecord
  belongs_to :student
  belongs_to :member

  validates :content, presence: true, length: { maximum: 1000 }
  validates :category, presence: true

  enum :category, {
    家庭から:         0,
    学校から:         1,
    ボランティアから: 2
  }
end

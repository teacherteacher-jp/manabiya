class StudentMemo < ApplicationRecord
  belongs_to :student
  belongs_to :member

  validates :content, presence: true, length: { maximum: 1000 }
  validates :category, presence: true

  after_create_commit :notify

  enum :category, {
    家庭から:         0,
    学校から:         1,
    ボランティアから: 2
  }

  def notify
    Notification.new.notify_student_memo_created(self)
  end
end

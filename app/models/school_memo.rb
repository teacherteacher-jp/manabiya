class SchoolMemo < ApplicationRecord
  belongs_to :member
  has_many :school_memo_students, dependent: :destroy
  has_many :students, through: :school_memo_students

  validates :content, presence: true, length: { maximum: 1000 }
  validates :category, presence: true
  validates :date, presence: true
  after_create_commit :notify

  enum :category, {
    家庭から:         0,
    コンコンから:     1,
    ボランティアから: 2
  }

  def notify
    Notification.new.notify_school_memo_created(self)
  end
end

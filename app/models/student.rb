class Student < ApplicationRecord
  belongs_to :parent_member, class_name: 'Member', optional: true
  has_many :memos, dependent: :destroy, class_name: 'StudentMemo'
  has_many :school_memo_students, dependent: :destroy
  has_many :school_memos, through: :school_memo_students

  validates :name, presence: true, length: { maximum: 20 }
  validates :grade, presence: true

  after_create_commit :notify_created
  after_update_commit :notify_updated

  enum :grade, {
    小学校1年生: 0,
    小学校2年生: 1,
    小学校3年生: 2,
    小学校4年生: 3,
    小学校5年生: 4,
    小学校6年生: 5,
    中学校1年生: 6,
    中学校2年生: 7,
    中学校3年生: 8,
    それ以外:    9
  }

  def notify_created
    Notification.new.notify_student_created(self)
  end

  def notify_updated
    Notification.new.notify_student_updated(self)
  end
end

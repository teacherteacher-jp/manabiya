class Student < ApplicationRecord
  belongs_to :parent_member, class_name: 'Member', optional: true
  has_many :memos, dependent: :destroy, class_name: 'StudentMemo'

  validates :name, presence: true, length: { maximum: 20 }
  validates :grade, presence: true

  after_create_commit :notify

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

  def notify
    Notification.new.notify_student_created(self)
  end
end

class Student < ApplicationRecord
  belongs_to :parent, class_name: 'Member', optional: true

  validates :name, presence: true, length: { maximum: 20 }
  validates :grade, presence: true

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
end

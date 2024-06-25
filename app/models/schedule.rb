class Schedule < ApplicationRecord
  belongs_to :member

  enum status: {
    ok: 0,
    ok_maybe: 1,
    ng: 2,
  }

  validates :member, presence: true
  validates :date, presence: true
  validates :status, presence: true
  validates :memo, length: { maximum: 255 }
end

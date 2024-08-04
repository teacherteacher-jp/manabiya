class Schedule < ApplicationRecord
  belongs_to :member
  has_one :assignment

  enum status: {
    ok: 0,
    ng: 2,
  }

  enum slot: {
    s1: 0,
    s2: 1,
    s3: 2,
    s4: 3,
  }

  validates :member, presence: true
  validates :date, presence: true
  validates :status, presence: true
  validates :memo, length: { maximum: 255 }

  scope :on, -> (date) { where(date: date) }

  class << self
    def statuses_in_symbols
      self.statuses.map { |key, value|
        [{ ok: "◯", ok_maybe: "△", ng: "✗" }[key.to_sym], value]
      }.to_h
    end

    def status_symbols
      %w[◯ △ ✗]
    end
  end

  def status_in_symbol
    Schedule.status_symbols[Schedule.statuses[status]]
  end
end

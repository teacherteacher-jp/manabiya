class Schedule < ApplicationRecord
  belongs_to :member
  has_one :assignment

  enum status: {
    ok: 0,
    ng: 2,
  }

  validates :member, presence: true
  validates :date, presence: true
  validates :status, presence: true
  validates :memo, length: { maximum: 255 }

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

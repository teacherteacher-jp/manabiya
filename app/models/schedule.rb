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

  SLOT_DETAILS = {
    s1: {
      time: "9:00~10:00",
      name: "探求",
    },
    s2: {
      time: "10:35~11:15",
      name: "国語",
    },
    s3: {
      time: "11:20~12:00",
      name: "算数",
    },
    s4: {
      time: "13:10~13:50",
      name: "お話",
    },
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

    def time_of(slot)
      SLOT_DETAILS[slot.to_sym][:time]
    end

    def name_of(slot)
      SLOT_DETAILS[slot.to_sym][:name]
    end
  end

  def status_in_symbol
    Schedule.status_symbols[Schedule.statuses[status]]
  end
end

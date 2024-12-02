class Event < ApplicationRecord
  validates :title, presence: true, length: { maximum: 50 }
  validates :description, presence: true, length: { maximum: 200 }
  validates :start_at, presence: true
  validates :venue, presence: true, length: { maximum: 50 }
  validates :source_link, presence: true

  def link_to_add_to_google_calendar
    dates = "#{start_at.strftime('%Y%m%dT%H%M%S')}/#{(start_at + 1.hour).strftime('%Y%m%dT%H%M%S')}"
    "https://calendar.google.com/calendar/render?action=TEMPLATE&text=#{title}&dates=#{dates}&details=#{description}&location=#{venue}&ctz=Asia/Tokyo"
  end
end

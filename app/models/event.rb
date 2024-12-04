class Event < ApplicationRecord
  include ApplicationHelper

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, presence: true, length: { maximum: 200 }
  validates :start_at, presence: true
  validates :venue, presence: true, length: { maximum: 50 }
  validates :source_link, presence: true

  scope :in_future, -> { where("start_at > ?", Time.current) }
  after_create_commit :notify

  class << self
    def notify_upcoming_events
      beginning_of_today = Time.current.beginning_of_day
      end_of_day_after_tommorow = 2.days.since.end_of_day
      events = Event.where(start_at: beginning_of_today..end_of_day_after_tommorow).order(start_at: :asc)
      Notification.new.notify_events(events:, content: "近日開催のイベントをお知らせ")
    end

    def notify_events_in_this_week
      events = Event.where(start_at: Time.current.all_week).order(start_at: :asc)
      Notification.new.notify_events(events:, content: "今週開催のイベントをお知らせ")
    end
  end

  def link_to_add_to_google_calendar
    dates = "#{start_at.strftime('%Y%m%dT%H%M%S')}/#{(start_at + 1.hour).strftime('%Y%m%dT%H%M%S')}"
    "https://calendar.google.com/calendar/render?action=TEMPLATE&text=#{title}&dates=#{dates}&location=#{venue}&ctz=Asia/Tokyo"
  end

  def to_embed
    {
      title: title,
      fields: [
        { name: "開始日時", value: mdwhm(start_at), inline: true },
        { name: "場所", value: venue, inline: true },
        { name: "詳細", value: "[リンクを開く](#{source_link})", inline: true },
        { name: "便利リンク", value: "[Googleカレンダーに追加する](#{link_to_add_to_google_calendar})", inline: true },
      ]
    }
  end

  def notify
    Notification.new.notify_event(event: self, content: "新着イベントをお知らせ")
  end
end

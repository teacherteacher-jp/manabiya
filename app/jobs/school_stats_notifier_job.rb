class SchoolStatsNotifierJob < ApplicationJob
  queue_as :default

  def perform
    return if Oyasumi.oyasumi?(Date.today)

    Notification.new.notify_school_stats
  end
end

class NotificationsController < ApplicationController
  def create
    schedules = Schedule.ok.on(params[:date])
    notice = nil

    if schedules.any?(&:assignment)
      Notification.new.notify_schedules(schedules)
      notice = "Discordに通知しました"
    end

    redirect_to(schedule_assignments_path(date: params[:date]), notice: notice)
  end
end

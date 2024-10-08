class SchedulesController < ApplicationController
  def index
    @dates = Date.today.upto(1.week.since.end_of_week.to_date).reject { Oyasumi.oyasumi?(_1) }
    @schedules = Schedule.where("date >= ?", Date.today)
  end

  def create
    schedules_params = params.require(:schedules).map do |schedule_params|
      schedule_params.permit(:date, :slot, :status, :memo).tap do |sp|
        sp[:status] = sp[:status].to_i if sp[:status].present?
      end
    end

    schedules_params.each do |s_param|
      status = s_param[:status]
      next if status.blank?

      date = s_param[:date]
      slot = s_param[:slot]
      memo = s_param[:memo].presence

      schedule = current_member.schedules.find_or_initialize_by(date: date, slot: slot)
      schedule.update(status: status, memo: memo)
    end

    Notification.new.notify_member_schedule_input(
      member: current_member,
      dates: schedules_params.select { _1[:status].present? }.map { _1[:date] },
    )

    redirect_to(my_schedules_path, notice: "スケジュールを保存しました")
  end
end

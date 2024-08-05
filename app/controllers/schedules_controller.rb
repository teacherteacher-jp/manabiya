class SchedulesController < ApplicationController
  def index
    @dates = Date.today.upto(Date.today + 14.days).reject { Oyasumi.oyasumi?(_1) }
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

    redirect_to(me_path, notice: "スケジュールを保存しました")
  end
end

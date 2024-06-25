class SchedulesController < ApplicationController
  def index
    @dates = Date.today.upto(Date.today + 14.days).reject { _1.wday.in?([0, 6]) }
    @schedules = Schedule.where("date >= ?", Date.today)
  end

  def create
    schedule = Schedule.new(schedule_params)
    schedule.member = current_member
    schedule.save

    redirect_to schedules_path
  end

  def update
    schedule = current_member.schedules.find_by(date: params[:schedule][:date])
    schedule.update(schedule_params)

    redirect_to schedules_path
  end

  def schedule_params
    params.require(:schedule).permit(:date, :status, :memo).tap do |schedule_params|
      schedule_params[:status] = schedule_params[:status].to_i
    end
  end
end

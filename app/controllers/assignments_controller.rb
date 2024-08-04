class AssignmentsController < ApplicationController
  def index
    @date = params[:date]
    @slots_and_schedules = Schedule.ok.on(@date).group_by(&:slot).sort_by { _1 }.to_h
    @assignments_yes, @assignments_no = Schedule.ok.on(@date).partition(&:assignment)
  end

  def create
    schedule = Schedule.find(params[:schedule_id])
    assignment = Assignment.new(schedule: schedule)
    assignment.save

    redirect_to schedule_assignments_path(schedule.date)
  end

  def destroy
    schedule = Schedule.find(params[:schedule_id])
    assignment = Assignment.find_by(schedule: schedule)
    assignment.destroy

    redirect_to schedule_assignments_path(schedule.date)
  end
end

class My::SchedulesController < ApplicationController
  def index
    @dates = Date.today.upto(1.week.since.end_of_week.to_date).reject { Oyasumi.oyasumi?(_1) }
    @vacation_period = Oyasumi.current_vacation_period
  end
end

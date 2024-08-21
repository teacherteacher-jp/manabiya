class MeController < ApplicationController
  def index
    @dates = Date.today.upto(1.week.since.end_of_week.to_date).reject { Oyasumi.oyasumi?(_1) }
  end
end

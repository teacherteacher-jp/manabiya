class MeController < ApplicationController
  def index
    @dates = Date.today.upto(Date.today + 14.days)
  end
end

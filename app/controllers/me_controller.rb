class MeController < ApplicationController
  def index
    @dates = Date.today.upto(Date.today + 14.days).reject { Oyasumi.oyasumi?(_1) }
  end
end

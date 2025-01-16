class Events::InPastController < ApplicationController
  def index
    @events = Event.in_past.order(start_at: :desc)
  end
end

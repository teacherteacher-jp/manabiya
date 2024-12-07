class Public::EventsController < ActionController::Base
  def index
    @events = Event.order(start_at: :desc)
  end
end

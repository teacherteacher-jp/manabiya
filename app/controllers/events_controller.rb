class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def index
    @events = Event.order(start_at: :asc)
  end

  def show
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to @event, notice: 'イベントが作成されました'
    else
      render :new
    end
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: 'イベントが更新されました'
    else
      render :edit
    end
  end

  private

  def event_params
    params.require(:event).permit(:title, :description, :start_at, :venue, :source_link)
  end

  def set_event
    @event = Event.find(params[:id])
  end
end

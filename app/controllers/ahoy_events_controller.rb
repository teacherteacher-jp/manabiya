class AhoyEventsController < ApplicationController
  before_action :require_admin

  def index
    @events = Ahoy::Event.includes(:visit, :member).order(time: :desc)
    @events = @events.where(member_id: params[:member_id]) if params[:member_id].present?
    @events = @events.where(name: params[:name]) if params[:name].present?
    @events = @events.where("properties::text ILIKE ?", "%#{params[:properties]}%") if params[:properties].present?
    @events = @events.page(params[:page]).per(50)

    @event_members = Member.where(id: Ahoy::Event.select(:member_id).distinct).order(:name)
    @event_names = Ahoy::Event.distinct.pluck(:name).compact.sort
  end
end

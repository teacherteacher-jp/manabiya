class RegionsController < ApplicationController
  def index
    @regions = Region.order(:id).includes(:members)
    @my_regions = current_member.member_regions
  end
end

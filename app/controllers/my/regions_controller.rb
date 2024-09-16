class My::RegionsController < ApplicationController
  def index
    @member_regions = current_member.member_regions.order(:category)
  end
end

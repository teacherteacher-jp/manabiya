class MembersController < ApplicationController
  def show
    @member = Member.find(params[:member_id])
  end
end

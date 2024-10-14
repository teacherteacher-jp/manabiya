class MembersController < ApplicationController
  def show
    @member = Member.find(params[:member_id])
    @family_members = @member.family_members.sort_by(&:order_score)
  end
end

class MemberRegionsController < ApplicationController
  def create
    mr = current_member.member_regions.new(member_region_params)
    mr.save

    redirect_to(my_regions_path, notice: "地域を登録しました")
  end

  def destroy
    mr = current_member.member_regions.find(params[:member_region_id])
    mr.destroy

    redirect_to(my_regions_path, notice: "地域の登録を解除しました")
  end

  def member_region_params
    params.require(:member_region).permit(:category, :region_id)
  end
end

class MemberRegionsController < ApplicationController
  def create
    mr = current_member.member_regions.new(region_id: params[:member_region][:region_id])
    mr.save

    redirect_to(regions_path, notice: "居住地を登録しました")
  end

  def destroy
    mr = current_member.member_regions.find(params[:member_region_id])
    mr.destroy

    redirect_to(regions_path, notice: "居住地の登録を解除しました")
  end
end

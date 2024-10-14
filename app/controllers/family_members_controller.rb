class FamilyMembersController < ApplicationController
  def create
    family_member = current_member.family_members.build(family_member_params)
    family_member.save

    redirect_to(my_family_members_path)
  end

  def destroy
    family_member = current_member.family_members.find(params[:family_member_id])
    family_member.destroy

    redirect_to(my_family_members_path)
  end

  def edit
    @family_member = current_member.family_members.find(params[:family_member_id])
  end

  def update
    family_member = current_member.family_members.find(params[:family_member_id])
    family_member.update(family_member_params)

    redirect_to(my_family_members_path)
  end

  def family_member_params
    params.require(:family_member).permit(:relationship, :display_name, :cohabiting, :birth_date)
  end
end

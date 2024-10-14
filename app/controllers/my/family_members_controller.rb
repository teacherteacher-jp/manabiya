class My::FamilyMembersController < ApplicationController
  def index
    @family_members = current_member.family_members.sort_by(&:order_score)
  end
end

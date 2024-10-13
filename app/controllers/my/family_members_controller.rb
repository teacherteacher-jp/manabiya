class My::FamilyMembersController < ApplicationController
  def index
    @family_members = current_member.family_members
  end
end

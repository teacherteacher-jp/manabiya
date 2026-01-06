class DevController < ApplicationController
  def login
    member = Member.find(params[:member_id])
    log_in(member)
    redirect_to root_path, notice: "🔧 Dev: #{member.name} でログイン"
  end
end

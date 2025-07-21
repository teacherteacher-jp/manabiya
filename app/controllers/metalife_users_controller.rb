class MetalifeUsersController < ApplicationController
  before_action :require_admin

  def index
    @metalife_users = MetalifeUser.includes(:linkable).order(created_at: :desc)
  end

  def update
    @metalife_user = MetalifeUser.find(params[:id])

    if params[:linkable_type].present? && params[:linkable_id].present?
      linkable = params[:linkable_type].constantize.find(params[:linkable_id])
      @metalife_user.update!(linkable: linkable)
    else
      @metalife_user.update!(linkable: nil)
    end

    redirect_to metalife_users_path, notice: "紐付けを更新しました"
  end

  private

  def require_admin
    redirect_to root_path unless current_member&.admin?
  end
end

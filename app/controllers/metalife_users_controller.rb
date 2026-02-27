class MetalifeUsersController < ApplicationController
  before_action :require_admin

  def index
    @scope = %w[unlinked_active unlinked_inactive linked].include?(params[:scope]) ? params[:scope].to_sym : :unlinked_active

    recently_active_user_ids = MetalifeEvent.where("occurred_at >= ?", 1.month.ago).distinct.pluck(:metalife_user_id)

    @linked_count = MetalifeUser.linked.count
    @unlinked_active_count = MetalifeUser.where(linkable_type: nil, id: recently_active_user_ids).count
    @unlinked_inactive_count = MetalifeUser.where(linkable_type: nil).where.not(id: recently_active_user_ids).count

    base = MetalifeUser.includes(:linkable).order(created_at: :desc)
    @metalife_users = case @scope
    when :unlinked_active then base.where(linkable_type: nil, id: recently_active_user_ids)
    when :unlinked_inactive then base.where(linkable_type: nil).where.not(id: recently_active_user_ids)
    else base.linked
    end
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
end

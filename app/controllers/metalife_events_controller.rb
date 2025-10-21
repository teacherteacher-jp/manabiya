class MetalifeEventsController < ApplicationController
  before_action :require_admin

  def index
    # 日付範囲の設定(デフォルトは過去7日間)
    @end_date = params[:end_date]&.to_date || Date.current
    @start_date = params[:start_date]&.to_date || @end_date - 6.days

    # 指定期間内のイベントを取得
    events = MetalifeEvent
               .includes(:metalife_user)
               .where(occurred_at: @start_date.beginning_of_day..@end_date.end_of_day)
               .order(occurred_at: :desc)

    # 日付ごとにグループ化
    @events_by_date = events.group_by { |event| event.occurred_at.to_date }

    # 各日付内でユーザーごとにグループ化し、時系列順にソート
    @events_by_date.transform_values! do |date_events|
      date_events
        .group_by(&:metalife_user)
        .transform_values { |user_events| user_events.sort_by(&:occurred_at) }
        .sort_by { |user, _events| user.name }
    end
  end

  private

  def require_admin
    redirect_to root_path unless current_member&.admin?
  end
end

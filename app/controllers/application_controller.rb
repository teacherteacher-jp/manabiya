class ApplicationController < ActionController::Base
  include SessionHelper
  before_action :force_expected_host
  before_action :redirect_to_gate_unless_logged_in

  def force_expected_host
    return unless Rails.env.production?

    redirect_to(Rails.application.credentials.base_url, allow_other_host: true) if request.host.include?(".herokuapp.com")
  end

  def redirect_to_gate_unless_logged_in
    redirect_to gate_path unless logged_in?
  end

  private

  def redirect_if_no_student_info_access
    unless current_member.can_access_student_info?
      redirect_to root_path, alert: 'アクセス権限がありません'
    end
  end
end

class ApplicationController < ActionController::Base
  include SessionHelper
  before_action :force_expected_host
  before_action :redirect_to_gate_unless_logged_in

  def force_expected_host
    return unless Rails.env.production?

    redirect_to Rails.application.credentials.base_url if request.host.include?(".herokuapp.com")
  end

  def redirect_to_gate_unless_logged_in
    redirect_to gate_path unless logged_in?
  end
end

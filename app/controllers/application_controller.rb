class ApplicationController < ActionController::Base
  include SessionHelper
  before_action :redirect_to_gate_unless_logged_in

  def redirect_to_gate_unless_logged_in
    redirect_to gate_path unless logged_in?
  end
end

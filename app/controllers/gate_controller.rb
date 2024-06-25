class GateController < ApplicationController
  skip_before_action :redirect_to_gate_unless_logged_in

  def index
  end
end

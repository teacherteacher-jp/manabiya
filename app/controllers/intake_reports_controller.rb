class IntakeReportsController < ApplicationController
  before_action :require_admin, only: [:index]
  before_action :set_report, only: [:show]

  def index
    @intake_reports = IntakeReport
      .includes(intake_session: [:intake, :member])
      .order(created_at: :desc)
  end

  def show
  end

  private

  def set_report
    @intake_report = IntakeReport.find(params[:id])
  end
end

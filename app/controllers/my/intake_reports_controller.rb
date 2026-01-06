class My::IntakeReportsController < ApplicationController
  def index
    @intake_reports = IntakeReport
      .joins(:intake_session)
      .where(intake_sessions: { member_id: current_member.id })
      .includes(intake_session: :intake)
      .order(created_at: :desc)
  end
end

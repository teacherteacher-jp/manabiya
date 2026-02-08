class IntakeSessionsController < ApplicationController
  include ActionController::Live

  skip_forgery_protection only: :stream
  before_action :set_intake, only: [:new, :create]
  before_action :set_session, only: [:show, :stream]

  def new
    @intake_session = @intake.intake_sessions.build
  end

  def create
    @intake_session = @intake.intake_sessions.build(member: current_member)

    if @intake_session.save
      redirect_to intake_session_path(@intake_session)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def stream
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    message = params[:message].to_s.strip

    begin
      agent = Intakes::AgentLoop.new(
        session: @intake_session,
        on_delta: ->(text) {
          escaped = text.gsub("\n", "\\n")
          response.stream.write("event: delta\ndata: #{escaped}\n\n")
        },
        on_tool_use: ->(tool_name) {
          response.stream.write("event: tool\ndata: #{tool_name}\n\n")
        }
      )

      if message.blank?
        agent.start_conversation
      else
        agent.process_user_message(message)
      end

      @intake_session.reload
      response.stream.write("event: done\ndata: #{@intake_session.status}\n\n")
    rescue StandardError => e
      Rails.logger.error("Intake stream error: #{e.message}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      response.stream.write("event: error\ndata: #{e.message}\n\n")
    ensure
      response.stream.close
    end
  end

  private

  def set_intake
    @intake = Intake.find(params[:intake_id])
  end

  def set_session
    @intake_session = current_member.intake_sessions.find(params[:id])
  end
end

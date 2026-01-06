class IntakesController < ApplicationController
  before_action :require_admin
  before_action :set_intake, only: [:show, :edit, :update, :destroy]

  def index
    @intakes = Intake.order(created_at: :desc)
  end

  def show
  end

  def new
    @intake = Intake.new
  end

  def create
    @intake = Intake.new(intake_params)
    if @intake.save
      redirect_to @intake, notice: '問診が作成されました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @intake.update(intake_params)
      redirect_to @intake, notice: '問診が更新されました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @intake.destroy
    redirect_to intakes_path, notice: '問診が削除されました'
  end

  private

  def intake_params
    params.require(:intake).permit(:title, :description, :report_format)
  end

  def set_intake
    @intake = Intake.find(params[:id])
  end
end

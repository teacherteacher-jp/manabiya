class IntakeItemsController < ApplicationController
  before_action :require_admin
  before_action :set_intake
  before_action :set_intake_item, only: [:edit, :update, :destroy]

  def new
    @intake_item = @intake.intake_items.build
  end

  def create
    @intake_item = @intake.intake_items.build(intake_item_params)
    @intake_item.position = @intake.intake_items.maximum(:position).to_i + 1

    if @intake_item.save
      redirect_to @intake, notice: '項目が追加されました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @intake_item.update(intake_item_params)
      redirect_to @intake, notice: '項目が更新されました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @intake_item.destroy
    redirect_to @intake, notice: '項目が削除されました'
  end

  private

  def intake_item_params
    params.require(:intake_item).permit(:name, :description, :position)
  end

  def set_intake
    @intake = Intake.find(params[:intake_id])
  end

  def set_intake_item
    @intake_item = @intake.intake_items.find(params[:id])
  end
end

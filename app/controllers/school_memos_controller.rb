class SchoolMemosController < ApplicationController
  before_action :set_school_memo, only: [:edit, :update, :destroy]
  before_action :redirect_if_not_authorized, only: [:edit, :update, :destroy]

  def index
    @school_memos = SchoolMemo.includes(:member, :students).order(id: :desc)
  end

  def new
    @school_memo = SchoolMemo.new
    @school_memo.student_ids = params[:student_ids].presence
  end

  def create
    @school_memo = current_member.school_memos.new(school_memo_params)

    if @school_memo.save
      if @school_memo.students.any?
        redirect_to student_path(@school_memo.students.first), notice: "メモを追加しました"
      else
        redirect_to root_path, notice: "メモを追加しました"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @school_memo.update(school_memo_params)
      if @school_memo.students.any?
        redirect_to student_path(@school_memo.students.first), notice: "メモを更新しました"
      else
        redirect_to root_path, notice: "メモを更新しました"
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    student = @school_memo.students.first
    @school_memo.destroy
    if student
      redirect_to student_path(student), notice: "メモを削除しました"
    else
      redirect_to root_path, notice: "メモを削除しました"
    end
  end

  private

  def set_school_memo
    @school_memo = SchoolMemo.find(params[:id])
  end

  def redirect_if_not_authorized
    unless current_member.can_edit?(@school_memo)
      redirect_to root_path, alert: "権限がありません"
    end
  end

  def school_memo_params
    params.require(:school_memo).permit(:content, :category, student_ids: [])
  end
end

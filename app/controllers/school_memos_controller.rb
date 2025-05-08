class SchoolMemosController < ApplicationController
  before_action :set_school_memo, only: [:edit, :update, :destroy]
  before_action :redirect_if_no_student_info_access

  def index
    @school_memos = SchoolMemo.includes(:member, :students).order(id: :desc)
  end

  def new
    @school_memo = SchoolMemo.new
    @school_memo.student_ids = params[:student_ids].split(",").map(&:to_i) if params[:student_ids].present?
  end

  def create
    @school_memo = current_member.school_memos.new(school_memo_params)

    if @school_memo.save
      redirect_to school_memos_path, notice: 'メモを追加しました'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @school_memo.update(school_memo_params)
      redirect_to school_memos_path, notice: 'メモを更新しました'
    else
      render :edit
    end
  end

  def destroy
    @school_memo.destroy
    redirect_to school_memos_path, notice: 'メモを削除しました'
  end

  private

  def set_school_memo
    @school_memo = SchoolMemo.find(params[:id])
  end

  def school_memo_params
    params.require(:school_memo).permit(:content, :category, student_ids: [])
  end
end

class SchoolMemosController < ApplicationController
  before_action :set_school_memo, only: [:edit, :update, :destroy]
  before_action :redirect_if_no_student_info_access
  before_action :set_students_for_form, only: [:new, :edit]

  def index
    @page = params[:page].present? ? params[:page].to_i : 1
    @school_memos_count = SchoolMemo.count
    @school_memos = SchoolMemo.includes(:member, :students).order(date: :desc, id: :desc).page(@page).per(20)
  end

  def new
    @school_memo = SchoolMemo.new
    @school_memo.date = Date.today
    @school_memo.student_ids = params[:student_ids].split(",").map(&:to_i) if params[:student_ids].present?
  end

  def create
    @school_memo = current_member.school_memos.new(school_memo_params)

    if @school_memo.save
      redirect_to school_memos_path, notice: 'メモを追加しました'
    else
      set_students_for_form
      render :new
    end
  end

  def edit
  end

  def update
    if @school_memo.update(school_memo_params)
      redirect_to school_memos_path, notice: 'メモを更新しました'
    else
      set_students_for_form
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

  def set_students_for_form
    all_students = Student.includes(:guardians, metalife_user: :metalife_events)
    @recent_students, @other_students = all_students.partition(&:recently_entered?)
  end

  def school_memo_params
    params.require(:school_memo).permit(:content, :category, :date, student_ids: [])
  end
end

class StudentsController < ApplicationController
  before_action :set_student, only: [:show, :edit, :update, :destroy]
  before_action :redirect_if_no_student_info_access

  def index
    @students = Student.order(id: :desc)
  end

  def show
    @page = params[:page].present? ? params[:page].to_i : 1
    @school_memos = @student.school_memos.order(date: :desc, id: :desc).page(@page).per(10)
  end

  def new
    @student = Student.new
  end

  def create
    @student = Student.new(student_params)

    if @student.save
      redirect_to @student, notice: '生徒を登録しました'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @student.update(student_params)
      redirect_to @student, notice: '生徒情報を更新しました'
    else
      render :edit
    end
  end

  def destroy
    @student.destroy
    redirect_to students_path, notice: '生徒を削除しました'
  end

  private

  def set_student
    @student = Student.includes(:metalife_user).find(params[:id])
  end

  def student_params
    params.require(:student).permit(:name, :grade, :parent_member_id)
  end
end

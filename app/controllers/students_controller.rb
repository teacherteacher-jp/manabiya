class StudentsController < ApplicationController
  before_action :set_student, only: [:show, :edit, :update]
  before_action :check_authorization, only: [:new, :create, :edit, :update]

  def index
    @students = Student.order(id: :desc)
  end

  def show
    @memos = @student.memos.order(id: :desc)
  end

  def new
    @student = Student.new
  end

  def create
    @student = Student.new(student_params)

    if @student.save
      redirect_to students_path, notice: '生徒を登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @student.update(student_params)
      redirect_to student_path(@student), notice: '生徒情報を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  def check_authorization
    unless current_member.admin?
      redirect_to root_path, alert: "権限がありません"
    end
  end

  def student_params
    params.require(:student).permit(:name, :grade, :parent_member_id)
  end
end

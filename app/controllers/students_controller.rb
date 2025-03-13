class StudentsController < ApplicationController
  def index
    @students = Student.order(id: :desc)
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

  private

  def student_params
    params.require(:student).permit(:name, :grade, :parent_member_id)
  end
end

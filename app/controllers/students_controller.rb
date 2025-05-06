class StudentsController < ApplicationController
  def index
    @students = Student.order(id: :desc)
  end

  def show
    @student = Student.find(params[:id])
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
    @student = Student.find(params[:id])
  end

  def update
    @student = Student.find(params[:id])

    if @student.update(student_params)
      redirect_to student_path(@student), notice: '生徒情報を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def student_params
    params.require(:student).permit(:name, :grade, :parent_member_id)
  end
end

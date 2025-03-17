class StudentMemosController < ApplicationController
  def create
    student = Student.find(params[:student_id])
    memo = student.memos.build(student_memo_params)
    memo.member = current_member

    if memo.save
      redirect_to(student, notice: "メモを追加しました")
    else
      redirect_to(student, alert: "メモの追加に失敗しました")
    end
  end

  private

  def student_memo_params
    params.require(:student_memo).permit(:content, :category)
  end
end

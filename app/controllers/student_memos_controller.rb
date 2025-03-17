class StudentMemosController < ApplicationController
  before_action :set_memo, only: [:edit, :update, :destroy]
  before_action :ensure_owner, only: [:edit, :update, :destroy]

  def create
    @student = Student.find(params[:student_id])
    @memo = @student.memos.build(student_memo_params)
    @memo.member = current_member

    if @memo.save
      redirect_to student_path(@student), notice: 'メモを追加しました'
    else
      redirect_to student_path(@student), alert: 'メモの追加に失敗しました'
    end
  end

  def edit
    @student = @memo.student
  end

  def update
    if @memo.update(student_memo_params)
      redirect_to student_path(@memo.student), notice: 'メモを更新しました'
    else
      @student = @memo.student
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    student = @memo.student
    @memo.destroy
    redirect_to student_path(student), notice: 'メモを削除しました'
  end

  private

  def set_memo
    @memo = StudentMemo.find(params[:id])
  end

  def ensure_owner
    unless @memo.member == current_member
      redirect_to student_path(@memo.student), alert: '他のメンバーのメモは編集できません'
    end
  end

  def student_memo_params
    params.require(:student_memo).permit(:content, :category)
  end
end

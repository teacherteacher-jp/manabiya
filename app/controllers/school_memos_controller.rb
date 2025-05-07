class SchoolMemosController < ApplicationController
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

  def update
    @school_memo = SchoolMemo.find(params[:id])
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
    @school_memo = SchoolMemo.find(params[:id])
    student = @school_memo.students.first
    @school_memo.destroy
    if student
      redirect_to student_path(student), notice: "メモを削除しました"
    else
      redirect_to root_path, notice: "メモを削除しました"
    end
  end

  private

  def school_memo_params
    params.require(:school_memo).permit(:content, :category, student_ids: [])
  end
end

class Students::SchoolMemosController < ApplicationController
  before_action :redirect_if_no_student_info_access
  before_action :set_student

  def index
    @school_memos = @student.school_memos
                            .includes(:member)
                            .order(date: order_direction, id: order_direction)

    if params[:start_date].present?
      @school_memos = @school_memos.where(date: params[:start_date]..)
    end

    if params[:end_date].present?
      @school_memos = @school_memos.where(date: ..params[:end_date])
    end

    @export_text = generate_export_text
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  def order_direction
    params[:order] == 'asc' ? :asc : :desc
  end

  def generate_export_text
    text = ""

    @school_memos.each do |memo|
      if show_column?('date')
        text += "■ #{memo.date.strftime('%Y年%-m月%-d日')}（#{%w[日 月 火 水 木 金 土][memo.date.wday]}）\n"
      end

      if show_column?('category')
        text += "カテゴリ: #{memo.category}\n"
      end

      if show_column?('member')
        text += "記録者: #{memo.member.name}\n"
      end

      if show_column?('content')
        text += "#{memo.content}\n"
      end

      text += "\n"
    end

    text
  end

  def show_column?(column)
    return true if params[:columns].blank?
    params[:columns].include?(column)
  end
end

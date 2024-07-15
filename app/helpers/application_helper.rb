module ApplicationHelper
  def mdw(date)
    "%d/%d(%s)" % [date.to_date.month, date.to_date.day, %w[日 月 火 水 木 金 土][date.wday]]
  end
end

module ApplicationHelper
  def mdw(date)
    "%d/%d(%s)" % [date.to_date.month, date.to_date.day, %w[日 月 火 水 木 金 土][date.wday]]
  end

  def mdwhm(time)
    "%s %s" % [mdw(time), time.strftime("%H:%M")]
  end
end

module ApplicationHelper
  def markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener" }
    )
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true
    )
    markdown.render(text).html_safe
  end

  def mdw(date)
    "%d/%d(%s)" % [date.to_date.month, date.to_date.day, %w[日 月 火 水 木 金 土][date.wday]]
  end

  def ymdw(date)
    "%d-%02d-%02d(%s)" % [date.to_date.year, date.to_date.month, date.to_date.day, %w[日 月 火 水 木 金 土][date.wday]]
  end

  def mdwhm(time)
    "%s %s" % [mdw(time), time.strftime("%H:%M")]
  end
end

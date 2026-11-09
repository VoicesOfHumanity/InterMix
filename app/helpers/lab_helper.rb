module LabHelper
  def lab_pct(x)
    x.nil? ? '–' : "#{(x * 100).round}%"
  end

  # Horizontal bar for a pick rate; the tick marks the 40% you'd get by chance
  def lab_bar(cell, mine: false)
    rate = cell.rate
    width = rate ? (rate * 100).clamp(0, 100).round : 0
    classes = ['bar']
    classes << 'thin' unless cell.enough?
    classes << 'mine' if mine
    content_tag(:span, class: classes.join(' '), title: "picked #{cell.picked} of #{cell.shown} times shown") do
      content_tag(:span, '', class: 'fill', style: "width: #{width}%") +
        content_tag(:span, '', class: 'chance', style: "left: #{(Lab::Tally::BASE * 100).round}%")
    end
  end

  def lab_author_badge(answer)
    if answer.ai?
      content_tag(:span, 'AI-drafted from your answers', class: 'badge ai')
    elsif answer.author_kind == 'demo'
      content_tag(:span, 'demo', class: 'badge demo')
    end
  end
end

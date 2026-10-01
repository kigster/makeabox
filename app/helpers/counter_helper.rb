# frozen_string_literal: true

# The download counter in the header, drawn as a seven-segment display.
# counter_controller.js redraws it the same way when the count changes.
module CounterHelper
  # Digits on the display; the count grows into the blank ones.
  COUNTER_DIGITS = 8

  # Groups of three digits, each lit over a faint row of eights, the way an
  # unlit segment still shows on an LED display. Blank digits are "!", which
  # the DSEG font draws as an empty digit. No count yet shows as dashes.
  def counter_digits(total)
    shown = total.nil? ? '-' * COUNTER_DIGITS : total.to_s.rjust(COUNTER_DIGITS, '!')
    groups = shown.reverse.scan(/.{1,3}/).map(&:reverse).reverse
    safe_join(groups.map do |group|
      tag.span(class: 'group') { tag.span('8' * group.size, class: 'off') + tag.span(group, class: 'on') }
    end)
  end

  def counter_label(total)
    total.nil? ? 'Download count unavailable' : "#{number_with_delimiter(total)} boxes downloaded since 2015"
  end
end

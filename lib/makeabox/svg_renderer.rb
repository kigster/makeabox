# frozen_string_literal: true

module Makeabox
  # laser-cutter (2.0.0 and 2.0.1) works out the size of the page again for every line it
  # writes to an SVG, which makes a 10 inch box take eight seconds instead of
  # a twentieth of one. The size cannot change while rendering, so it is kept.
  #
  # Remove this class once the gem remembers the size itself.
  class SvgRenderer < Laser::Cutter::Renderer::SvgRenderer
    private

    def width
      @width ||= super
    end

    def height
      @height ||= super
    end
  end
end

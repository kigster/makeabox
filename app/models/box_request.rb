# frozen_string_literal: true

require 'tempfile'

# One request for a box: the form's parameters, checked, and turned into a
# drawing by the laser-cutter gem.
class BoxRequest
  DIMENSIONS = %i[width height depth thickness].freeze
  OPTIONAL   = %i[notch kerf margin padding stroke].freeze
  UNITS      = %w[in mm].freeze
  LAYOUTS    = %w[portrait landscape].freeze
  FORMATS    = { 'pdf' => 'application/pdf', 'svg' => 'image/svg+xml' }.freeze

  # How the top panel joins the walls, in laser-cutter's own words: 'full' is
  # notched on all four sides, 'back' only where it meets the back wall, and
  # 'plain' is a rectangle that lies on top. The last two lift off.log
  LIDS = %w[full back plain].freeze

  LABELS = { notch: 'Notch length' }.freeze

  # The narrowest notch worth cutting, per unit. The widest is a third of the
  # shortest side. On a box too small for both, the narrowest drops to half
  # the widest. Both ends are rounded down to NOTCH_DIGITS decimals, exactly
  # as generator_controller.js does, so the page and the server agree.
  NOTCH_MIN    = { 'in' => 0.2, 'mm' => 5.0 }.freeze
  NOTCH_DIGITS = { 'in' => 2, 'mm' => 1 }.freeze

  # More notches than this along one edge is a drawing of tens of thousands
  # of lines that takes seconds to make and no laser cuts well.
  MAX_NOTCHES = 150

  # makeabox's kerf when the field is blank. laser-cutter's own, 0.0024 in,
  # leaves most boxes loose; this one suits most wood.
  KERF_DEFAULT = { 'in' => 0.026, 'mm' => 0.66 }.freeze

  class << self
    # laser-cutter 2.0.0 draws only the full lid. Releases that draw the
    # others say so with Laser::Cutter::Box::LIDS.
    def lids_supported?
      Laser::Cutter::Box.const_defined?(:LIDS)
    end

    # @return [Hash] what the gem fills in when a field is left blank, per unit
    def defaults
      gem_defaults = Laser::Cutter::Configuration.defaults
      UNITS.index_with { |unit| gem_defaults[unit].to_h.transform_values { |value| value.round(4) }.merge('kerf' => KERF_DEFAULT.fetch(unit)) }
    end

    # @return [Hash] page sizes per unit, as [name, width, height]
    def page_sizes
      UNITS.to_h do |unit|
        digits = unit == 'in' ? 1 : 0
        [unit, Laser::Cutter::PageManager.new(unit).page_size_values.map { |name, w, h| [name, w.round(digits), h.round(digits)] }]
      end
    end
  end

  attr_reader :errors

  # @param params [Hash, ActionController::Parameters] the `box` parameters of the form
  def initialize(params)
    @params = params.to_h.symbolize_keys
    @errors = []
  end

  def valid?
    @errors = []
    check_dimensions
    check_optional
    check_notch if errors.empty?
    check_notch_count if errors.empty?
    check_choices
    errors.empty?
  end

  def units
    UNITS.include?(@params[:units]) ? @params[:units] : UNITS.first
  end

  def lid
    LIDS.include?(@params[:lid]) ? @params[:lid] : LIDS.first
  end

  # @return [String] a file name that says which box is inside
  def filename(format)
    size = DIMENSIONS.first(3).map { |key| trim(number(key)) }.join('x')
    "makeabox-#{size}#{units}-#{trim(number(:thickness))}t.#{format}"
  end

  # Draws the box and returns the file's bytes. Yields the number of lines
  # drawn so far and the total, once per line.
  #
  # @param format [String] 'pdf' or 'svg'
  # @return [String]
  def render(format)
    Tempfile.create(['makeabox', ".#{format}"]) do |file|
      renderer = renderer_for(format, configuration(file.path))
      total = renderer.total
      done = 0
      renderer.render { yield(done += 1, total) if block_given? }
      File.binread(file.path)
    end
  end

  # @return [Laser::Cutter::Configuration]
  def configuration(file)
    options = { units: units, file: file, metadata: @params[:metadata] != '0',
                page_layout: LAYOUTS.include?(@params[:page_layout]) ? @params[:page_layout] : LAYOUTS.first }
    (DIMENSIONS + OPTIONAL).each { |key| options[key] = number(key) if number(key) }
    options[:kerf] ||= KERF_DEFAULT.fetch(units)
    options[:page_size] = @params[:page_size] if @params[:page_size].present?
    options[:lid] = lid if self.class.lids_supported? && lid != LIDS.first
    Laser::Cutter::Configuration.new(options).tap(&:validate!)
  end

  private

  def renderer_for(format, config)
    format.to_s == 'svg' ? Makeabox::SvgRenderer.new(config) : Laser::Cutter::Renderer.for(format, config)
  end

  def number(key)
    Float(@params[key].to_s.tr(',', '.'), exception: false)
  end

  def trim(value)
    format('%.4f', value).sub(/\.?0+\z/, '')
  end

  def label(key)
    LABELS.fetch(key) { key.to_s.capitalize }
  end

  def sides
    DIMENSIONS.first(3).map { |key| number(key) }
  end

  def check_dimensions
    DIMENSIONS.each do |key|
      errors << "#{label(key)} needs a number above zero." unless number(key)&.positive? && number(key).finite?
    end
    return unless errors.empty?

    errors << 'Thickness has to be smaller than the shortest side of the box.' if number(:thickness) >= sides.min
  end

  # Kerf, margin and padding may be zero. laser-cutter refuses a zero stroke,
  # and a zero notch has no meaning.
  def check_optional
    limit = errors.empty? ? sides.max : Float::INFINITY
    OPTIONAL.each do |key|
      next if @params[key].blank?

      value = number(key)
      if value.nil? || value.negative? || !value.finite?
        errors << "#{label(key)} needs a number, or leave it blank."
      elsif value.zero? && %i[notch stroke].include?(key)
        errors << "#{label(key)} has to be above zero, or leave it blank."
      elsif value > limit
        errors << "#{label(key)} cannot be larger than the box."
      end
    end
  end

  # @return [Array(Float, Float)] the narrowest and the widest notch allowed
  def notch_range
    widest = round_down(sides.min / 3)
    [[NOTCH_MIN.fetch(units), round_down(widest / 2)].min, widest]
  end

  def round_down(value)
    scale = 10.0**NOTCH_DIGITS.fetch(units)
    ((value * scale) + 1e-6).floor / scale
  end

  def check_notch
    return if @params[:notch].blank?

    narrowest, widest = notch_range
    return if number(:notch).between?(narrowest - 1e-9, widest + 1e-9)

    errors << "Notch length has to be between #{trim(narrowest)} and #{trim(widest)} #{units}, or blank."
  end

  # Counts the notches on the longest edge the way laser-cutter does.
  def check_notch_count
    notch = number(:notch) || (3 * number(:thickness))
    count = (sides.max / notch).round(6).ceil + 1
    count = (count / 2 * 2) + 1 # always odd
    return if count <= MAX_NOTCHES

    errors << "That is #{count} notches along the longest side, and #{MAX_NOTCHES} is the most we draw. " \
              'Use thicker material or a longer notch.'
  end

  # A choice that is not on the list is refused, not quietly replaced: a box
  # asked for in "MM" must not come back drawn in inches.
  def check_choices
    { units: UNITS, lid: LIDS, page_layout: LAYOUTS }.each do |key, known|
      value = @params[key]
      errors << "#{value} is not one of #{known.join(', ')}." if value.present? && known.exclude?(value)
    end
    size = @params[:page_size]
    errors << "#{size} is not a page size we know." if size.present? && !Laser::Cutter::PageManager::SIZES.key?(size)
    errors << 'This lid needs laser-cutter 2.0.1 or newer.' if lid != LIDS.first && !self.class.lids_supported?
  end
end

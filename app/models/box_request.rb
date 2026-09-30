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
  # 'plain' is a rectangle that lies on top. The last two lift off.
  LIDS = %w[full back plain].freeze

  LABELS = { notch: 'Tab width' }.freeze

  class << self
    # laser-cutter 2.0.0 draws only the full lid. Releases that draw the
    # others say so with Laser::Cutter::Box::LIDS.
    def lids_supported?
      Laser::Cutter::Box.const_defined?(:LIDS)
    end

    # @return [Hash] what the gem fills in when a field is left blank, per unit
    def defaults
      gem_defaults = Laser::Cutter::Configuration.defaults
      UNITS.index_with { |unit| gem_defaults[unit].to_h.transform_values { |value| value.round(4) } }
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

  def check_dimensions
    DIMENSIONS.each do |key|
      errors << "#{label(key)} needs a number above zero." unless number(key)&.positive?
    end
    return unless errors.empty?

    smallest = DIMENSIONS.first(3).map { |key| number(key) }.min
    errors << 'Thickness has to be smaller than the shortest side of the box.' if number(:thickness) >= smallest
  end

  def check_optional
    OPTIONAL.each do |key|
      next if @params[key].blank?

      errors << "#{label(key)} needs a number, or leave it blank." unless number(key) && !number(key).negative?
    end
  end

  def check_choices
    size = @params[:page_size]
    errors << "#{size} is not a page size we know." if size.present? && !Laser::Cutter::PageManager::SIZES.key?(size)
    errors << 'This lid needs a newer laser-cutter than the one installed.' if lid != LIDS.first && !self.class.lids_supported?
  end
end

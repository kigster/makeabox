module HomeHelper
  FIELD_NAME_MAP = {
    'notch' => 'Tab Width'
  }.freeze

  def field_name(field)
    FIELD_NAME_MAP[field] || field.to_s.capitalize
  end

  def config_form_element_group(keys = [], config = {}, label = true, tabindex_start = nil)
    keys.map do |field|
      config_form_element(config, field, label, tabindex_start)
    end.join('')
  end

  def config_form_element(config, field, label, tabindex_start)
    content_tag('p', class: 'form-label-and-element') do
      name    = "config[#{field}]"
      options = input_field_options(tabindex_start)

      label_tag(name, label ? field_name(field) : '') +
        number_field_tag(name, config[field], options)
    end
  end

  def input_field_options(tabindex_start)
    {
      min: 0.0,
      step: 0.01,
      class: 'numeric',
      tabindex: tabindex_start
    }
  end

  def validate_config!
    @config.validate!
    true
  rescue Laser::Cutter::MissingOption, Laser::Cutter::ZeroValueNotAllowed => e
    flash[:error] = self.latest_error = clarify_error(e.message)
    logger.warn e.message
    false
  rescue StandardError => e
    flash[:error] = self.latest_error = e.message
    logger.error('ERROR: ' + e.inspect + "\n" + e.backtrace.join("\n"))
    false
  end

  def clarify_error(message)
    m = message.gsub(/,? ?notch,?/i, '')
    if m.split(',').size == 2
      m.gsub(/are required/, 'is required')
    else
      m
    end
  end

  def handle_cache_control
    # if request.get? && params[:config].nil?
    #   expires_in 15.minutes, :public => true, must_validate: true
    # end
  end

  NUMERIC_FIELDS = %w[width height depth thickness notch page_size kerf].freeze

  def create_new_config
    c = params[:config] || {}

    NUMERIC_FIELDS.each do |f|
      c[f] = nil if (c[f] == '0') || c[f].blank?
    end

    c[:metadata] = params[:metadata].blank? ? false : true

    @config         = Laser::Cutter::Configuration.new(c)
    @config['file'] = '/tmp/temporary'

    @config['file'] = exported_file_name if %w[width height depth thickness].all? { |f| c[f] }
  end

  def populate_form_fields
    @page_size_options = Laser::Cutter::PageManager.new(@config.units).page_size_values.map do |v|
      digits = @config.units.eql?('in') ? 1 : 0
      [format("%s %4.#{digits}f x %4.#{digits}f", *v), format('%s', v[0])]
    end
    @page_size_options.insert(0, ['Auto Fit the Box', ''])
  end

  def handle_units_change
    if params['units'] && params['units'] != @config.units
      @config.units = params['units']
      @config.change_units(params['units'] == 'in' ? 'mm' : 'in')
    end

    NUMERIC_FIELDS.each do |field|
      @config[field] = @config[field].round(5) if @config[field] && @config[field].to_f > 0
    end
  end

  def generate_pdf_filename
    ["#{pdf_export_folder}/makeabox.io",
     timestamp,
     (fmt :units, type: 's', width: '2.2').to_s,
     "#{fmt :width}[w]x#{fmt :height}[h]x#{fmt :depth}[d]",
     "#{fmt :thickness, width: '.3'}[t]",
     "#{fmt :kerf, width: '.4'}[k]",
     "#{fmt :stroke, width: '.3'}[s]" +
       '.pdf'].join('-')
  end

  def pdf_export_folder
    "#{Rails.root}/tmp/pdfs"
  end

  def fmt(field, type: 'f', width: '.1')
    format "%#{width}#{type}", @config.send(field)
  end

  def timestamp
    Time.now.strftime('%Y%m%d%H%M%S')
  end

  require 'fileutils'

  def exported_file_name
    FileUtils.mkdir_p(pdf_export_folder)
    generate_pdf_filename
  end
end

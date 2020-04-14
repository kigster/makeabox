# frozen_string_literal: true

class HomeController < ApplicationController
  attr_accessor :latest_error

  before_action :load_parameters,
                :populate_form_fields,
                :handle_units_change

  def index
    unless params['commit'].eql?('true')
      flash.clear
      return
    end

    if latest_error
      flash.now[:error] = latest_error
      @error = latest_error
      render && return
    end

    not_cacheable!

    flash.clear

    if validate_config!
      generate_pdf @config
    end

    render
  end

  private

  def validate_config!
    @config.validate!
    true
  rescue Rack::Timeout::Error => e
    flash[:error] = 'Your request exceeded the maximum of 30 seconds allowed. Please reduce tab width parameter, or leave it empty.'
    Rails.logger.warn "Timeout Error: #{e.message}"
    false
  rescue Laser::Cutter::MissingOption, Laser::Cutter::ZeroValueNotAllowed => e
    flash[:error] = self.latest_error = clarify_error(e.message)
    Rails.logger.info e.message
    false
  rescue StandardError => e
    flash[:error] = self.latest_error = e.message
    Rails.logger.error("ERROR: " + e.inspect + "\n" + e.backtrace.join("\n"))
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

  def load_parameters
    c = params[:config] || {}

    %w[width height depth thickness notch page_size kerf].each do |f|
      c[f] = nil if (c[f] == '0') || c[f].blank?
    end

    c[:metadata] = params[:metadata].blank? ? false : true

    @config = Laser::Cutter::Configuration.new(c)
    @config['file'] = '/tmp/temporary'

    if %w[width height depth thickness].all? { |f| c[f] }
      @config['file'] = exported_file_name
    end

    validate_config!
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
  end

  require 'fileutils'

  def exported_file_name
    pdf_export_folder = "#{Rails.root}/tmp/pdfs"
    FileUtils.mkdir_p(pdf_export_folder)
    "#{pdf_export_folder}/makeabox-#{format '%.2f', @config.width}W-#{format '%.2f', @config.height}H-#{format '%.2f', @config.depth}D-#{format '%.2f', @config.thickness}T-#{timestamp}.pdf"
  end

  def timestamp
    Time.now.strftime '%Y%m%d%H%M%S'
  end

  def generate_pdf(config)
    r = Laser::Cutter::Renderer::LayoutRenderer.new(config)
    r.render
    temp_files << config['file']
    send_file config['file'], type: 'application/pdf; charset=utf-8', status: 200
    config['file']
  end
end

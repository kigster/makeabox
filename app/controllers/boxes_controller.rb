# frozen_string_literal: true

class BoxesController < ApplicationController
  before_action :authenticate_user!

  attr_accessor :latest_error

  before_action :load_parameters, only: %i(new create)
  before_action :populate_form_fields, only: %i(new)
  before_action :handle_units_change, only: %i(new create)

  def new
    request.session[:box] = nil
    # flash.clear
  end

  def create
    unless params['commit'].eql?('true')
      flash.now[:error] = 'Please submit form with all values included.'
      redirect_back fallback_location: '/', allow_other_host: false
      return
    end

    if latest_error
      flash.now[:error] = latest_error
      @error            = latest_error
      render and return
    end

    not_cacheable!

    begin
      @config.validate!
      request.session[:box]         = {}
      request.session[:box][:file]  = @config['file']
      request.session[:box][:start] = Time.now

      FileGeneratorWorker.perform_async(@config.to_hash, session.id)
      redirect_to :check_job_status
    rescue StandardError => e
      self.latest_error = e.message
      flash.now[:error] = latest_error
      redirect_back fallback_location: '/', allow_other_host: false
      Rails.logger.error(e.backtrace&.join("\n"))
    end
    # end
  end

  def check_job_status
    if request.session[:box].blank?
      flash.now[:error] = 'Nothing found in the session'
      return redirect_to :root_path
    end

    file = request.session[:box][:file]

    if file.blank?
      flash.now[:error] = 'File name was not defined'
      return redirect_to :root_path
    end

    if File.exist?(file)
      redirect_to boxes_path
    else
      head :accepted
    end
  end

  def show
    file = request.session[:box][:file]
    if file && File.exist?(file)
      send_file file, type: 'application/pdf; charset=utf-8', status: 200
      redirect_to :new_boxes
    else
      Rails.logger.error("File #{file} does not exist...")
      flash.now[:error] = 'Can not find the generated file'
    end
  end

  private

  def handle_cache_control
    # if request.get? && params[:config].nil?
    #   expires_in 15.minutes, :public => true, must_validate: true
    # end
  end

  def load_parameters
    c = params[:config] || {}
    %w(width height depth thickness notch page_size kerf).each do |f|
      c[f] = nil if (c[f] == '0') || c[f].blank?
    end
    c[:metadata]    = !params[:metadata].blank?
    @config         = Laser::Cutter::Configuration.new(c)
    @config['file'] = exported_file_name if %w(width height depth thickness).all? { |f| c[f] }
    begin
      @config.validate!
      Rails.logger.info 'config validation OK'
      true
    rescue StandardError => e
      Rails.logger.error "config validation failed with error: #{e}"
      self.latest_error = e.message
      false
    end
  end

  def populate_form_fields
    @page_size_options = Laser::Cutter::PageManager.new(@config.units).page_size_values.map do |v|
      digits = @config.units.eql?('in') ? 1 : 0
      [sprintf("%s %4.#{digits}f x %4.#{digits}f", *v), sprintf("%s", v[0])]
    end
    @page_size_options.insert(0, ['Auto Fit the Box', ''])
  end

  def handle_units_change
    return unless params['units'] && params['units'] != @config.units

    @config.units = params['units']
    @config.change_units(params['units'] == 'in' ? 'mm' : 'in')
  end

  require 'fileutils'

  def exported_file_name
    pdf_export_folder = "#{Rails.root}/tmp/pdfs"
    FileUtils.mkdir_p(pdf_export_folder)
    "#{pdf_export_folder}/makeabox-#{sprintf '%.2f', @config.width}W-#{sprintf '%.2f', @config.height}H-#{sprintf '%.2f', @config.depth}D-#{sprintf '%.2f', @config.thickness}T-#{timestamp}.pdf"
  end

  def timestamp
    Time.now.strftime '%Y%m%d%H%M%S'
  end

  def timeout
    Rails.configuration.x.job_timeout
  end
end

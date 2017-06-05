class HomeController < ApplicationController
  attr_accessor :latest_error

  before_action :load_parameters,
                :populate_form_fields,
                :handle_units_change


  def index
    if params['commit'].eql?('true')
      if latest_error
        flash.now[:error] = latest_error
        @error            = latest_error
        render and return
      end
      not_cacheable!
      logging "Dumped file [#{@config['file']}]" do
        begin
          @config.validate!
          generate_pdf @config
        rescue Exception => e
          self.latest_error = e.message
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end
    else
      flash.clear
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
      c[f] = nil if c[f] == '0' or c[f].blank?
    end
    c[:metadata]    = params[:metadata].blank? ? false : true
    @config         = Laser::Cutter::Configuration.new(c)
    @config['file'] = exported_file_name if %w(width height depth thickness).all? {|f| c[f]}
    begin
      @config.validate!
      Rails.logger.info 'config validation OK'
      true
    rescue Exception => e
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
    if params['units'] && params['units'] != @config.units
      @config.units = params['units']
      @config.change_units(params['units'] == 'in' ? 'mm' : 'in')
    end
  end

  require 'fileutils'

  def exported_file_name
    pdf_export_folder="#{Rails.root}/tmp/pdfs"
    FileUtils.mkdir_p(pdf_export_folder)
    "#{pdf_export_folder}/makeabox-#{sprintf '%.2f', @config.width}W-#{sprintf '%.2f', @config.height}H-#{sprintf '%.2f', @config.depth}D-#{sprintf '%.2f', @config.thickness}T-#{timestamp}.pdf"
  end

  def timestamp
    Time.now.strftime '%Y%m%d%H%M%S'
  end

  def generate_pdf(config)
    r = Laser::Cutter::Renderer::LayoutRenderer.new(config)
    r.render
    self.temp_files << config['file']
    send_file config['file'], type: 'application/pdf; charset=utf-8', status: 200
  end


end

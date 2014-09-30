class HomeController < ApplicationController
  def index
    @config = Laser::Cutter::Configuration.new(params[:config] || {} )
    if params['units'] && params['units'] != @config.units
      @config.units = params['units']
      @config.change_units(params['units'] == 'in' ? 'mm' : 'in')
    end
    @page_size_options = @config.page_size_values.map do |v|
      digits = @config.units.eql?('in') ? 1 : 0
      [ sprintf("%s %4.#{digits}f x %4.#{digits}f", *v), sprintf("%s", v[0]) ]
    end

    %w(width height depth thickness notch).each do |f|
      @config[f] = nil if @config[f] == 0.0
    end

    if params['commit']
      @config['file'] = "/tmp/makeabox-io-#{@config.width}x#{@config.height}x#{@config.depth}-#{rand(10000)}.box.pdf"
      begin
        @config.validate!
        generate_pdf @config
      rescue Exception => e
        @error = e.message
      #ensure
      #  File.delete(@config['file']) rescue nil
      end
    end
  end

  private

  def generate_pdf(config)
    r = Laser::Cutter::Renderer::BoxRenderer.new(config)
    r.render
    send_file config['file'], type: 'application/pdf; charset=utf-8', status: 200
  end


end

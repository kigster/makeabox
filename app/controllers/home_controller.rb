# frozen_string_literal: true

class HomeController < ApplicationController
  attr_accessor :latest_error

  DEFAULT_PARAMS_KEYS = %w[controller action].freeze

  def index
    create_new_config
    populate_form_fields
    handle_units_change

    if request.get? && parameter_keys.empty?
      Rails.cache.fetch('/index', expires_in: 1.hour) do
        render_index_action
      end
    else
      render_index_action
    end
  end

  private

  include HomeHelper

  def parameter_keys
    params.keys - DEFAULT_PARAMS_KEYS
  end

  def render_index_action
    return(render) if request.get?

    validate_config!

    if params['commit'].eql?('true')
      if latest_error
        flash.now[:error] = latest_error
        @error            = latest_error
        return(render)
      end

      not_cacheable!

      flash.clear

      if validate_config!
        defined?(::Datadog) ? trace_make_and_send_pdf(@config) : make_and_send_pdf(@config)
      else
        render
      end
    end
  rescue Rack::Timeout::Error => e
    if defined?(::Datadog)
      ::Datadog.tracer.active_span&.set_tag('pdf.file.status', 2)
      ::Datadog.tracer.active_span&.set_tag('pdf.file.error', e.message)
    end
    flash[:error] = 'Your request exceeded the maximum of 30 seconds allowed. Please reduce tab width parameter, or leave it empty.'
    logger.warn "Timeout Error: #{e.message}"
    false
  end

  def make_pdf(config)
    logging "making PDF(#{config['file']}" do
      Laser::Cutter::Renderer::LayoutRenderer.new(config).render
    end
  end

  def send_pdf(config)
    logging "sending PDF(#{config['file']}" do
      temp_files << config['file']
      send_file config['file'], type: 'application/pdf; charset=utf-8', status: 200
      config['file']
    end
  end

  def make_and_send_pdf(config)
    %i[make_pdf send_pdf].each { |m| send(m, config) }
  end

  def trace_make_and_send_pdf(config)
    Datadog.tracer.trace('web.request.pdf', service: 'makeabox', resource: 'POST /') do |span|
      # Trace the activerecord call
      Datadog.tracer.trace('pdf.render') do
        make_pdf(config)
      end

      # Trace the template rendering
      Datadog.tracer.trace('pdf.sendfile') do
        send_pdf(config)
      end

      begin
        # Add some APM tags
        span.set_tag('pdf.box.count', temp_files.size)
        span.set_tag('pdf.box.units', config.units)
        span.set_tag('pdf.box.size', "#{config.width}x#{config.height}x#{config.depth} (#{config.thickness})")
        span.set_tag('pdf.box.notch', config.notch)
        span.set_tag('pdf.box.kerf', config.kerf)

        if config.file && File.exist?(config.file)
          span.set_tag('pdf.file.name', config.file)
          span.set_tag('pdf.file.size', ::File.size(config.file)) if File.exist?(config.file)
          span.set_tag('pdf.file.status', 0)
        else
          span.set_tag('pdf.file.status', 1)
        end
      rescue StandardError => e
        logger.warn("Error processing tags for DataDog: #{e.inspect}")
        logger.warn("Config: #{config.inspect}")
      end
    end
  end
end

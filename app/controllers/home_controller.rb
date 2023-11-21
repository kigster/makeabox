# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
    create_new_config
    populate_form_fields
    handle_units_change

    Rails.logger.info("config: #{@config}")

    @refine_ad_type = proc { %w[dark light].sample }.call

    # let's roll the coin. Get the dark or the light.
    if request.get? && permitted_params.empty?
      logging('index from the cache [ ✔ ]', ip: request.remote_ip) do |extra|
        Rails.cache.fetch(homepage_cache_key, race_condition_ttl: 10.seconds, expires_in: 1.hour) do
          extra[:message] += ', but not this time [ ✖ ]'
          render
        end
      end
    elsif request.post?
      if validate_config!
        render_box_pdf_template!
      else
        render
      end
    end
  end

  protected

  # @return [String (frozen)]
  def homepage_cache_key
    create_cache_key("#{controller_name}.#{action_name}.#{request.method}")
  end

  private

  include HomeHelper

  def render_box_pdf_template!
    validate_config!.tap do |result|
      Rails.logger.info("configuration validation returned: #{result}")
    end || return

    if permitted_params['commit'].eql?('true')
      if latest_error
        flash.now[:error] = latest_error
        @error            = latest_error
        render
      else
        not_cacheable!
        flash.clear
        make_pdf(@config)
        send_pdf(@config)
      end
    end
  rescue Rack::Timeout::Error => e
    flash[:error] =
      'Your request exceeded the maximum of 30 seconds allowed. Please reduce tab width parameter, or leave it empty.'
    logger.warn 'Timeout Error', reason: e.message
    false
  end

  def make_pdf(config)
    logging('generating PDF', config: config, ip: request.remote_ip) do
      Laser::Cutter::Renderer::LayoutRenderer.new(config).render
    end
  end

  def send_pdf(config)
    logging('sending PDF', config: config, ip: request.remote_ip) do
      send_file config['file'], type: 'application/pdf; charset=utf-8', status: 200
      garbage_collect(config['file'])
      config['file']
    end
  end

  def make_and_send_pdf(config)
    make_pdf(config)
    send_pdf(config)
  end
end

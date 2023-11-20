# frozen_string_literal: true

class HomeController < ApplicationController
  attr_accessor :latest_error

  DEFAULT_PARAMS_KEYS = %w[controller action].freeze

  def index
    create_new_config
    populate_form_fields
    handle_units_change

    @refine_ad_type = ad_card_random_color

    # let's roll the coin. Get the dark or the light.
    if request.get? && parameter_keys.empty?
      logging('index from the cache [ ✔ ]', ip: request.remote_ip) do |extra|
        Rails.cache.fetch(homepage_cache_key, race_condition_ttl: 10.seconds, expires_in: 1.hour) do
          extra[:message] += ', but not this time [ ✖ ]'
          render_index_action(request, params)
        end
      end
    else
      render_index_action(request, params)
    end
  end

  protected

  # @return [String]
  def ad_card_random_color
    %w[dark light].sample || 'dark'
  end

  # @return [String (frozen)]
  def homepage_cache_key
    create_cache_key("#{controller_name}.#{action_name}.#{request.method}")
  end

  private

  include HomeHelper

  def parameter_keys
    params.keys - DEFAULT_PARAMS_KEYS
  end

  def render_index_action(request, params)
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
      render
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
    %i[make_pdf send_pdf].each { |m| send(m, config) }
  end
end

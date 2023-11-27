# frozen_string_literal: true

class HomeController < ApplicationController
  attr_reader :refine_ad_type

  # skip_before_action :verify_authenticity_token
  before_action :configure_params

  def index
    @refine_ad_type = proc { %w[dark light].sample }.call

    # let's roll the coin. Get the dark or the light.
    return unless request.get? && permitted_params.empty?

    logging('index from the cache [ ✔ ]', ip: request.remote_ip) do |extra|
      Rails.cache.fetch(homepage_cache_key, race_condition_ttl: 10.seconds, expires_in: 1.hour) do
        extra[:message] += ', but not this time [ ✖ ]'
        render
      end
    end
  end

  # post /make_my_box
  def make_my_box
    Rails.logger.info("generate_pdf: config: #{@config}")

    if request.get?
      flash[:error] = 'Please submit the form to generate a PDF.'
      redirect_to root_path
    end

    return unless request.post?

    if validate_config!
      render_box_pdf_template!
    else
      redirect_to root_path
    end
  end

  # get /check_box_status
  def check_box_status
    return unless request.xhr?

    job_id = session[:job_id]
    status = job_status(job_id)

    render json: { status: status.to_h }
  end

  # get /download
  def download
    send_pdf_when_ready(session[:job_id])
  end

  protected

  def configure_params
    create_new_config
    populate_form_fields
    handle_units_change
  end

  # @return [String (frozen)]
  def homepage_cache_key
    create_cache_key("#{controller_name}.#{action_name}.#{request.method}.#{session.id}")
  end

  private

  include HomeHelper
  include Makeabox::PDF::RedisConcern

  def render_box_pdf_template!
    if latest_error
      flash.now[:error] = latest_error
      @error            = latest_error
      render
    else
      @config[:session_id] = session.id.to_s
      jid = GeneratePDFWorker.perform_async(@config.to_hash)
      session[:job_id] = jid
      flash.now[:notice] = "Your PDF is being generated, job ID is #{jid}, please wait..."
    end
  end

  def job_status(job_id = session[:job_id])
    get_status(job_id)
  end

  def send_pdf_when_ready(job_id = nil)
    if job_id.nil?
      flash[:error] = 'Please submit the form to generate a PDF.'
      redirect_to root_path
    end

    status = job_status(job_id)

    if status.nil?
      render text: "Job #{job_id} is still processing..."
      return
    end

    if status.done?
      send_pdf(status.file)
    else
      render text: "PDF generation failed: #{status.error}"
    end
  end

  def send_pdf(file)
    logging('sending PDF', ip: request.remote_ip) do |extra|
      send_file file, type: 'application/pdf; charset=utf-8', generation_status: 200
      garbage_collect(file)
      extra[:message] = "sent #{file}"
    end
  end
end

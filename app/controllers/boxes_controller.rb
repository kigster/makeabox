# frozen_string_literal: true

class BoxesController < ApplicationController
  include ActionController::Live

  # At most this many progress events per drawing, however many lines it has,
  # plus one for the last line.
  PROGRESS_EVENTS = 50

  # BoxRequest keeps drawings small enough to take well under a second. This
  # is the backstop. Rack::Timeout cannot be it: the stream is drawn on
  # ActionController::Live's own thread, which Rack::Timeout never interrupts.
  RENDER_SECONDS = 20

  PERMITTED = (BoxRequest::DIMENSIONS + BoxRequest::OPTIONAL + %i[units page_size page_layout metadata lid]).freeze

  # Draws the SVG, reporting progress as it goes and sending the drawing last.
  def stream
    prepare_event_stream
    events = SSE.new(response.stream)
    box = BoxRequest.new(box_params)
    return events.write({ message: box.errors.join(' ') }, event: 'failed') unless box.valid?

    events.write({ svg: draw(box, events), filename: box.filename('svg') }, event: 'drawn')
  rescue ActionController::Live::ClientDisconnected
    logger.info('box stream: client went away')
  rescue Timeout::Error, Laser::Cutter::Error => e
    logger.warn("box stream failed: #{e.class}: #{e.message}")
    tell(events, failure_message(e))
  rescue StandardError => e
    # Anything else is our bug. Say so, or the page can only report silence.
    logger.error("box stream crashed: #{e.class}: #{e.message}\n#{e.backtrace&.first(8)&.join("\n")}")
    Rails.error.report(e, handled: true)
    tell(events, 'Something went wrong on our side while drawing this box. It has been logged.')
  ensure
    events&.close
  end

  def download
    return head(:not_found) if params[:format].present? && !BoxRequest::FORMATS.key?(params[:format])

    format = params[:format].presence || 'pdf'
    box = BoxRequest.new(box_params)
    return render(plain: box.errors.join(' '), status: :unprocessable_content) unless box.valid?

    bytes = logging("rendering #{format} for #{request.remote_ip}") { Timeout.timeout(RENDER_SECONDS) { box.render(format) } }
    send_data bytes, filename: box.filename(format), type: BoxRequest::FORMATS.fetch(format), disposition: 'attachment'
    Makeabox::BoxCounter.record_download(format)
  rescue Timeout::Error, Laser::Cutter::Error => e
    logger.warn("box download failed: #{e.class}: #{e.message}")
    render plain: failure_message(e), status: :unprocessable_content
  end

  private

  # `box` is only read as a set of fields: `?box=text` is treated as no box at all.
  def box_params
    params.permit(box: PERMITTED)[:box] || {}
  end

  # Sends the `failed` event. The reader may be gone by now, which is fine.
  def tell(events, message)
    events&.write({ message: message }, event: 'failed')
  rescue ActionController::Live::ClientDisconnected
    nil
  end

  def prepare_event_stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no' # keeps nginx from holding events back
    response.headers['Last-Modified'] = Time.now.httpdate # keeps Rack::ETag from buffering the body
  end

  def draw(box, events)
    step = nil
    logging("drawing svg for #{request.remote_ip}") do
      Timeout.timeout(RENDER_SECONDS) do
        box.render('svg') do |done, total|
          step ||= (total.to_f / PROGRESS_EVENTS).ceil
          events.write({ done: done, total: total }, event: 'progress') if (done % step).zero? || done == total
        end
      end
    end
  end

  def failure_message(error)
    if error.is_a?(Timeout::Error)
      return "That box took more than #{RENDER_SECONDS} seconds to draw. Try thicker material or a longer notch."
    end

    "laser-cutter could not draw this box: #{error.message}"
  end
end

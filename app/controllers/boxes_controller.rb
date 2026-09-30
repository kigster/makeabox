# frozen_string_literal: true

class BoxesController < ApplicationController
  include ActionController::Live

  # At most this many progress events per drawing, however many lines it has.
  PROGRESS_EVENTS = 50

  PERMITTED = (BoxRequest::DIMENSIONS + BoxRequest::OPTIONAL + %i[units page_size page_layout metadata lid]).freeze

  # Draws the SVG, reporting progress as it goes and sending the drawing last.
  def stream
    prepare_event_stream
    events = SSE.new(response.stream)
    box = BoxRequest.new(box_params)
    return events.write({ message: box.errors.join(' ') }, event: 'failed') unless box.valid?

    events.write({ svg: draw(box, events), filename: box.filename('svg') }, event: 'drawn')
  rescue ActionController::Live::ClientDisconnected, IOError
    logger.info('box stream: client went away')
  rescue Rack::Timeout::Error, Laser::Cutter::Error, ArgumentError => e
    logger.warn("box stream failed: #{e.class}: #{e.message}")
    events&.write({ message: failure_message(e) }, event: 'failed')
  ensure
    events&.close
  end

  def download
    format = BoxRequest::FORMATS.key?(params[:format]) ? params[:format] : 'pdf'
    box = BoxRequest.new(box_params)
    return render(plain: box.errors.join(' '), status: :unprocessable_content) unless box.valid?

    bytes = logging("rendering #{format}", ip: request.remote_ip) { box.render(format) }
    send_data bytes, filename: box.filename(format), type: BoxRequest::FORMATS.fetch(format), disposition: 'attachment'
  end

  private

  def box_params
    params.fetch(:box, {}).permit(*PERMITTED)
  end

  def prepare_event_stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no' # keeps nginx from holding events back
    response.headers['Last-Modified'] = Time.now.httpdate # keeps Rack::ETag from buffering the body
  end

  def draw(box, events)
    step = nil
    logging('drawing svg', ip: request.remote_ip) do
      box.render('svg') do |done, total|
        step ||= [total / PROGRESS_EVENTS, 1].max
        events.write({ done: done, total: total }, event: 'progress') if (done % step).zero? || done == total
      end
    end
  end

  def failure_message(error)
    return 'That box took more than 30 seconds to draw. Try a wider tab width, or leave it blank.' if error.is_a?(Rack::Timeout::Error)

    "laser-cutter could not draw this box: #{error.message}"
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Boxes' do
  let(:box) { { width: 5, height: 3, depth: 4, thickness: 0.245, units: 'in' } }

  # @return [Array<Array(String, Hash)>] the server-sent events as [name, data]
  def events
    response.body.split("\n\n").map do |chunk|
      [chunk[/^event: (.+)$/, 1], JSON.parse(chunk[/^data: (.+)$/m, 1])]
    end
  end

  describe 'GET /box/stream' do
    it 'reports progress, then sends the drawing' do
      get '/box/stream', params: { box: box }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq 'text/event-stream'
      expect(events.map(&:first).uniq).to eq %w[progress drawn]
      expect(events.last.last).to include('filename' => 'makeabox-5x3x4in-0.245t.svg', 'svg' => a_string_including('<svg'))
    end

    it 'counts the lines from the first step to the last' do
      get '/box/stream', params: { box: box }

      expect(events.first.last).to eq('done' => 7, 'total' => 376)
      expect(events[-2].last).to eq('done' => 376, 'total' => 376)
    end

    it 'never sends more than a few dozen progress events' do
      get '/box/stream', params: { box: box.merge(width: 20, height: 20, depth: 20, thickness: 0.125) }

      expect(events.count { |name, _| name == 'progress' }).to be <= BoxesController::PROGRESS_EVENTS + 2
    end

    it 'says what is wrong with the box' do
      get '/box/stream', params: { box: box.merge(width: 0) }

      expect(events).to eq [['failed', { 'message' => 'Width needs a number above zero.' }]]
    end

    it 'reports a drawing laser-cutter gives up on' do
      allow_any_instance_of(BoxRequest).to receive(:render).and_raise(Laser::Cutter::Error, 'no such notch') # rubocop:disable RSpec/AnyInstance

      get '/box/stream', params: { box: box }

      expect(events).to eq [['failed', { 'message' => 'laser-cutter could not draw this box: no such notch' }]]
    end

    it 'explains a timeout' do
      allow_any_instance_of(BoxRequest).to receive(:render).and_raise(Rack::Timeout::RequestTimeoutError.new({})) # rubocop:disable RSpec/AnyInstance

      get '/box/stream', params: { box: box }

      expect(events.last.last['message']).to start_with('That box took more than 30 seconds')
    end

    it 'survives a client that went away' do
      allow_any_instance_of(BoxRequest).to receive(:render).and_raise(ActionController::Live::ClientDisconnected) # rubocop:disable RSpec/AnyInstance

      expect { get '/box/stream', params: { box: box } }.not_to raise_error
    end

    it 'ignores parameters it does not know' do
      get '/box/stream', params: { box: box.merge(file: '/etc/passwd') }

      expect(events.last.first).to eq 'drawn'
    end
  end

  describe 'GET /box/download' do
    it 'sends the PDF as a file' do
      get '/box/download.pdf', params: { box: box }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq 'application/pdf'
      expect(response.headers['Content-Disposition']).to include('attachment', 'makeabox-5x3x4in-0.245t.pdf')
      expect(response.body).to start_with('%PDF-')
    end

    it 'sends the SVG as a file' do
      get '/box/download.svg', params: { box: box }

      expect(response.media_type).to eq 'image/svg+xml'
      expect(response.body).to include('<svg')
    end

    it 'defaults to the PDF' do
      get '/box/download', params: { box: box }

      expect(response.media_type).to eq 'application/pdf'
    end

    it 'says what is wrong with the box' do
      get '/box/download.pdf', params: { box: box.merge(thickness: 9) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to eq 'Thickness has to be smaller than the shortest side of the box.'
    end
  end
end

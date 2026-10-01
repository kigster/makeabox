# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Downloads' do
  let(:start) { Makeabox::BoxCounter::STARTING_TOTAL }

  it 'tells the page how many boxes have been downloaded' do
    get '/downloads'

    expect(response.parsed_body).to eq('total' => start)
  end

  it 'counts an SVG the page saved' do
    post '/downloads', params: { kind: 'svg' }

    expect(response.parsed_body).to eq('total' => start + 1)
    expect(Makeabox::BoxCounter.total).to eq start + 1
  end

  it 'leaves PDFs to the server that sends them' do
    post '/downloads', params: { kind: 'pdf' }

    expect(response).to have_http_status(:unprocessable_content)
    expect(Makeabox::BoxCounter.total).to eq start
  end

  it 'says so when there is no count to give' do
    allow(Makeabox::BoxCounter).to receive(:total).and_return(nil)

    get '/downloads'

    expect(response.parsed_body).to eq('total' => nil)
  end
end

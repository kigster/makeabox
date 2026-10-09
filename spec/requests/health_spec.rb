# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health check' do
  it 'answers 200 once the app has booted' do
    get '/up'

    expect(response).to have_http_status(:ok)
  end
end

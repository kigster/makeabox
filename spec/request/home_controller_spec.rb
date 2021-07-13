# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Request' do
  describe HomeController, type: :request do
    describe 'GET /' do
      it 'returns http success' do
        get '/'
        expect(response).to be_successful
      end
    end

    describe 'POST /' do
      it 'returns http success' do
        post '/'
        expect(response).to be_successful
      end
    end
  end
end

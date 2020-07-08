require 'rails_helper'

RSpec.describe 'Controller' do
  describe HomeController, type: :controller do
    describe 'GET /' do
      it 'returns http success' do
        get :index
        expect(response).to be_successful
      end
    end

    describe 'POST /' do
      it 'returns http success' do
        post :index
        expect(response).to be_successful
      end
    end
  end
end

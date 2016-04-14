require 'rails_helper'
RSpec.describe HomeController, :type => :controller do

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST index' do
    it 'returns http success' do
      post :index
      expect(response).to have_http_status(:success)
      puts response.body
    end
  end

end

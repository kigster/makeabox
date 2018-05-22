require 'rails_helper'
RSpec.describe HomeController, :type => :controller do

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'POST index' do
    it 'returns http success' do
      post :index
      expect(response).to be_successful
      puts response.body
    end
  end

end

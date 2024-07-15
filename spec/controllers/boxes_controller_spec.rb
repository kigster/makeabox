# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoxesController, type: :controller do
  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'POST create' do
    it 'returns http success' do
      post :create
      expect(response).to_not be_successful
    end
  end
end

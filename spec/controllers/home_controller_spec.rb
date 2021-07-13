# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET /' do
    it 'returns http success' do
      get :index
      expect(response).to be_successful
    end

    it 'activate caching: returns http success' do
      expect(Rails.cache).to receive(:fetch).and_call_original
      get :index
      expect(response).to be_successful

      expect(Rails.cache.read('/index-gets')).to_not be_nil
    end
  end

  describe 'POST /' do
    context 'with invalid or insufficient params' do
      it 'returns http success' do
        post :index
        expect(response).to be_successful
        expect(flash).to_not be_empty
        expect(flash['error']).to_not be_empty
        expect(flash['error']).to eq 'width, height, depth, thickness are required, but missing.'
      end
    end

    context 'with valid params' do
      let(:params) do
        { utf8: '✓',
          commit: 'true',
          units: 'in',
          config: { units: 'in',
                    page_layout: 'portrait',
                    width: '2',
                    height: '3',
                    depth: '4',
                    thickness: '0.125',
                    notch: '',
                    kerf: '0.0028',
                    margin: '0.125',
                    padding: '0.1',
                    stroke: '0.001',
                    page_size: '' } }.with_indifferent_access
      end

      it 'returns generates the PDF' do
        post :index, params: params
        expect(response).to be_successful
        expect(flash).to be_empty
      end
    end
  end
end

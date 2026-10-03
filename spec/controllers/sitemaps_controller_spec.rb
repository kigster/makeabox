# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SitemapsController, type: :controller do
  describe 'GET #show' do
    before { get :show, format: :xml }

    its(:response) { is_expected.to have_http_status(:ok) }

    it 'returns the committed sitemap as XML' do
      expect(response.media_type).to eq 'application/xml'
      sitemap = Nokogiri::XML(response.body, &:strict)
      expect(sitemap.root.namespace.href).to eq 'http://www.sitemaps.org/schemas/sitemap/0.9'
      expect(sitemap.css('url loc').map(&:text)).to eq ['https://makeabox.io/']
      expect(Date.iso8601(sitemap.at_css('url lastmod').text)).to be <= Time.zone.today
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Search engines' do
  it 'may crawl the page but not the drawings, and are told where the sitemap is' do
    get '/robots.txt'

    expect(response).to have_http_status(:ok)
    expect(response.body.lines.map(&:strip)).to include('User-agent: *', 'Allow: /', 'Disallow: /box/', 'Sitemap: https://makeabox.io/sitemap.xml')
  end

  it 'returns HTTP 200 with an XML content type' do
    get '/sitemap.xml'

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('application/xml').or eq('text/xml')
  end

  it 'find the page in the sitemap' do
    get '/sitemap.xml'

    sitemap = Nokogiri::XML(response.body, &:strict)
    expect(sitemap.root.namespace.href).to eq 'http://www.sitemaps.org/schemas/sitemap/0.9'
    expect(sitemap.css('url loc').map(&:text)).to eq ['https://makeabox.io/']
    expect(Date.iso8601(sitemap.at_css('url lastmod').text)).to be <= Time.zone.today
  end

  it 'is routed through Rails so production can serve it without nginx static files' do
    expect(Rails.application.routes.recognize_path('/sitemap.xml')).to include(
      controller: 'sitemaps', action: 'show'
    )
  end
end

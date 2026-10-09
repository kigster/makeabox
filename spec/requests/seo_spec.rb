# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Search engines' do
  it 'may crawl the page but not the drawings, and are told where the sitemap is' do
    get '/robots.txt'

    expect(response).to have_http_status(:ok)
    expect(response.body.lines.map(&:strip)).to include('User-agent: *', 'Allow: /', 'Disallow: /box/', 'Sitemap: https://makeabox.io/sitemap.xml')
  end

  it 'find the page in the sitemap' do
    get '/sitemap.xml'

    sitemap = Nokogiri::XML(response.body, &:strict)
    expect(sitemap.root.namespace.href).to eq 'http://www.sitemaps.org/schemas/sitemap/0.9'
    expect(sitemap.css('url loc').map(&:text)).to eq ['https://makeabox.io/']
    expect(Date.iso8601(sitemap.at_css('url lastmod').text)).to be <= Time.zone.today
  end

  describe 'the home page' do
    let(:page) { response.parsed_body }

    it 'names makeabox.io as its canonical address' do
      get '/'

      expect(page.css('link[rel=canonical]').pluck('href')).to eq ['https://makeabox.io/']
    end

    it 'keeps that address when the request carries tracking parameters' do
      get '/', params: { utm_source: 'newsletter', utm_campaign: 'fall', gclid: 'abc123' }

      expect(page.css('link[rel=canonical]').pluck('href')).to eq ['https://makeabox.io/']
    end

    it 'has one title naming the generator, its formats and the brand' do
      get '/'

      expect(page.css('title').map(&:text)).to eq ['Free Laser Cut Box Generator - SVG & PDF | makeabox']
    end

    it 'gives shared links the same title on every network' do
      get '/'

      og = page.at_css('meta[property="og:title"]')['content']
      expect(og).to include('Laser Cut Box Generator', 'SVG', 'PDF')
      expect(page.at_css('meta[name="twitter:title"]')['content']).to eq og
    end

    it 'introduces the generator in a paragraph under its one heading' do
      get '/'

      expect(page.css('h1').size).to eq 1
      expect(page.at_css('.hero .pitch p').text).to start_with('Set the inside dimensions and your material.')
      expect(page.css('h4')).to be_empty
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page' do
  before { get '/' }

  it 'renders the generator' do
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="generator"', 'Boxes that snap together')
  end

  it 'shows the logo next to the name' do
    expect(response.body).to match(%r{<a class="mark" href="/">\s*<img[^>]*src="/assets/mark-[^"]+\.svg"[^>]*>\s*makeabox})
  end

  it 'puts the particle canvas behind the page' do
    expect(response.body).to include('<canvas aria-hidden="true" class="sparks" data-controller="particles">')
  end

  it 'works as a plain form without JavaScript' do
    expect(response.body).to include('action="/box/download.pdf"', 'method="get"', 'name="box[width]"', 'name="box[thickness]"')
  end

  it 'hands the gem defaults and page sizes to the page' do
    expect(response.body).to include('&quot;kerf&quot;:0.0024', 'LETTER')
  end

  it 'offers the lids' do
    expect(response.body).to include('value="back"', 'value="plain"')
    expect(response.body).not_to match(/<option[^>]*disabled/)
    expect(response.body).not_to include('Lids need laser-cutter 2.0.1 or newer.')
  end

  it 'links to GitHub Discussions until giscus is configured' do
    expect(response.body).to include('https://github.com/kigster/makeabox/discussions')
    expect(response.body).not_to include('giscus.app')
  end

  it 'leaves analytics out outside production' do
    expect(response.body).not_to include('googletagmanager')
  end

  context 'when the installed laser-cutter cannot draw lids' do
    before do
      allow(BoxRequest).to receive(:lids_supported?).and_return(false)
      get '/'
    end

    it 'shows them disabled, with a note' do
      expect(response.body).to match(/<option[^>]*disabled[^>]*value="plain"|<option[^>]*value="plain"[^>]*disabled/)
      expect(response.body).to include('Lids need laser-cutter 2.0.1 or newer.')
    end
  end

  context 'when giscus is configured' do
    before do
      stub_const('ENV', ENV.to_h.merge('GISCUS_REPO_ID' => 'R_123', 'GISCUS_CATEGORY_ID' => 'DIC_456'))
      get '/'
    end

    it 'embeds the discussion' do
      expect(response.body).to include('https://giscus.app/client.js', 'data-repo-id="R_123"', 'data-category-id="DIC_456"')
    end
  end
end

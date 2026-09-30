# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page' do
  before { get '/' }

  it 'renders the generator' do
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="generator"', 'Boxes that snap together')
  end

  it 'works as a plain form without JavaScript' do
    expect(response.body).to include('action="/box/download.pdf"', 'name="box[width]"', 'name="box[thickness]"')
  end

  it 'hands the gem defaults and page sizes to the page' do
    expect(response.body).to include('&quot;kerf&quot;:0.0024', 'LETTER')
  end

  it 'offers the lids, disabled until laser-cutter can draw them' do
    expect(response.body).to match(/<option[^>]*disabled[^>]*value="plain"|<option[^>]*value="plain"[^>]*disabled/)
    expect(response.body).to include('Lids arrive with the next laser-cutter release.')
  end

  it 'links to GitHub Discussions until giscus is configured' do
    expect(response.body).to include('https://github.com/kigster/makeabox/discussions')
    expect(response.body).not_to include('giscus.app')
  end

  it 'leaves analytics out outside production' do
    expect(response.body).not_to include('googletagmanager')
  end

  context 'when laser-cutter can draw lids' do
    before do
      allow(BoxRequest).to receive(:lids_supported?).and_return(true)
      get '/'
    end

    it 'enables them' do
      expect(response.body).not_to include('Lids arrive with the next laser-cutter release.')
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

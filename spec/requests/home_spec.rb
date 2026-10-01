# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page' do
  before { get '/' }

  it 'renders the generator' do
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="generator"', 'boxes that snap together')
  end

  it 'shows the logo next to the name' do
    expect(response.body).to match(%r{<a class="mark" href="/">\s*<img[^>]*src="/assets/logo-[^"]+\.svg"[^>]*>\s*makeabox})
  end

  it 'gives a shared link a preview card with the logo and the name' do
    card = %r{http://www.example.com/assets/social-[^"]+\.png}
    expect(response.body).to include('property="og:title"', '<meta content="summary_large_image" name="twitter:card">')
    expect(response.body).to match(/<meta content="#{card}" property="og:image">/).and match(/<meta content="#{card}" name="twitter:image">/)
  end

  it 'shows how many boxes have been downloaded, in the header' do
    expect(response.body).to include('aria-label="1,300,000 boxes downloaded since 2015"', 'data-counter-total-value="1300000"', 'boxes downloaded</div>', 'since 2015</div>')
  end

  it 'explains kerf before the finer settings' do
    expect(response.body).to include('Kerf matters most', 'The default, 0.026 in (0.66 mm)')
  end

  it 'puts the particle canvas behind the page' do
    expect(response.body).to include('<canvas aria-hidden="true" class="sparks" data-controller="particles">')
  end

  it 'names both dialogs for a screen reader' do
    expect(response.body).to include('aria-labelledby="settings_title"', 'id="settings_title"', 'aria-labelledby="cut_title"', 'id="cut_title"')
  end

  it 'keeps the sections in panels that slide up over the controls' do
    expect(response.body).to include('data-controller="panels"', '<dialog aria-label="How the tabs work" class="rise"', 'id="discussion"', 'id="support"')
    expect(response.body).to include('data-panels-name-param="how"')
  end

  it 'works as a plain form without JavaScript' do
    expect(response.body).to include('action="/box/download.pdf"', 'method="get"', 'name="box[width]"', 'name="box[thickness]"')
  end

  it 'hands the gem defaults and page sizes to the page' do
    expect(response.body).to include('&quot;kerf&quot;:0.026', 'LETTER')
  end

  it 'offers the lids' do
    expect(response.body).to include('value="back"', 'value="plain"')
    expect(response.body).not_to match(/<option[^>]*disabled/)
    expect(response.body).not_to include('Lids need laser-cutter 2.0.1 or newer.')
  end

  it 'embeds the discussion' do
    expect(response.body).to include('https://giscus.app/client.js', "data-repo-id=\"#{ApplicationHelper::GISCUS_REPO_ID}\"",
                                     "data-category-id=\"#{ApplicationHelper::GISCUS_CATEGORY_ID}\"")
  end

  it 'links to GitHub Discussions when giscus is off' do
    allow_any_instance_of(ApplicationHelper).to receive(:giscus?).and_return(false) # rubocop:disable RSpec/AnyInstance
    get '/'
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
end

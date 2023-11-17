# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#asset_image' do
    subject(:url) { asset_image(image) }

    let(:image) { 'buttons/up-long/btn-donate-monthly.png' }

    it { is_expected.not_to be_nil }
    it { is_expected.not_to start_with 'http' }
    it { is_expected.to eq '/images/buttons/up-long/btn-donate-monthly.png' }
  end
end

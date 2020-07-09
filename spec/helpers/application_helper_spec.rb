require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#asset_image' do
    let(:image) { 'buttons/up-long/btn-donate-monthly.png' }
    subject(:url) { asset_image(image) }

    it { is_expected.to_not be_nil }
    it { is_expected.to_not start_with 'http' }
    it { is_expected.to eq '/images/buttons/up-long/btn-donate-monthly.png' }
  end
end

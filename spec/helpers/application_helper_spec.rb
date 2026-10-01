# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#tracking?' do
    it 'is off outside production' do
      expect(helper.tracking?).to be false
    end

    it 'is on in production' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('production'))
      expect(helper.tracking?).to be true
    end
  end

  describe '#giscus?' do
    it 'needs both ids' do
      stub_const('ENV', ENV.to_h.merge('GISCUS_REPO_ID' => 'R_123', 'GISCUS_CATEGORY_ID' => ''))
      expect(helper.giscus?).to be false
    end

    it 'is on with both' do
      stub_const('ENV', ENV.to_h.merge('GISCUS_REPO_ID' => 'R_123', 'GISCUS_CATEGORY_ID' => 'DIC_456'))
      expect(helper.giscus?).to be true
    end
  end
end

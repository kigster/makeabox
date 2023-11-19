# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe '#create_cache_key' do
    subject { controller.send(:create_cache_key, key) }

    let(:controller) { described_class.new }
    let(:rev) { controller.send(:git_rev_parse) }

    let(:key) { 'index' }

    it { is_expected.to eq "#{key}.#{rev}" }
  end
end

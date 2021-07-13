require 'rails_helper'

RSpec.describe MakeABox do
  describe '#memcached_options' do
    let(:type) { :cache }
    let(:rails_env) { 'test' }
    let(:expected_namespace) { "#{type}.#{rails_env}" }
    let(:result) { described_class.memcached_options(argument)[:namespace] }

    describe 'non-nil value' do
      subject { result }
      let(:argument) { :cache }
      it { is_expected.to eq(expected_namespace) }
    end
  end
end

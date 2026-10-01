# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Makeabox::BoxCounter do
  let(:start) { described_class::STARTING_TOTAL }

  it 'starts at the boxes downloaded before the count was kept' do
    expect(described_class.total).to eq 1_300_000
  end

  it 'counts each download from there, and returns the new total' do
    expect(described_class.record_download('pdf')).to eq start + 1
    expect(described_class.record_download('svg')).to eq start + 2
    expect(described_class.total).to eq start + 2
  end

  it 'keeps a count that has already started' do
    REDIS.with { |redis| redis.set(described_class::DOWNLOADS_KEY, 1_400_000) }

    expect(described_class.record_download('pdf')).to eq 1_400_001
  end

  it 'still counts where Redis has no time series' do
    allow_any_instance_of(Redis).to receive(:call).and_raise(Redis::CommandError, "ERR unknown command 'TS.ADD'") # rubocop:disable RSpec/AnyInstance

    expect(described_class.record_download('pdf')).to eq start + 1
  end

  context 'when Redis is down' do
    before { allow(REDIS).to receive(:with).and_raise(Redis::CannotConnectError, 'Connection refused') }

    it 'skips the count instead of failing the download' do
      expect(Rails.logger).to receive(:warn).with(a_string_including('box counter failed: Connection refused'))

      expect(described_class.record_download('pdf')).to be_nil
    end

    it 'has no total to show' do
      expect(described_class.total).to be_nil
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterHelper do
  # @return [Array<Array(String, String)>] each group as [unlit, lit]
  def groups(html)
    Nokogiri::HTML.fragment(html).css('.group').map { |group| [group.at_css('.off').text, group.at_css('.on').text] }
  end

  it 'draws the count in groups of three over unlit eights, blank to the left' do
    expect(groups(helper.counter_digits(1_300_042))).to eq [%w[88 !1], %w[888 300], %w[888 042]]
  end

  it 'shows dashes when there is no count' do
    expect(groups(helper.counter_digits(nil))).to eq [%w[88 --], %w[888 ---], %w[888 ---]]
  end

  it 'reads the count out in words' do
    expect(helper.counter_label(1_300_042)).to eq '1,300,042 boxes downloaded since 2015'
    expect(helper.counter_label(nil)).to eq 'Download count unavailable'
  end
end

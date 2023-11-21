# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdfGeneratorJob, type: :job do
  let(:job) { described_class.new }

  it 'is instantiated' do
    expect(job).to be_a(described_class)
  end
end

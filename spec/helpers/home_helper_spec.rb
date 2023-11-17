# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeHelper, type: :helper do
  describe '#generate_pdf_filename' do
    let(:params) do
      {
        config: {
          units: 'in',
          page_layout: 'portrait',
          width: '10',
          height: '15',
          depth: '5',
          thickness: '0.125',
          notch: '',
          kerf: '0.0024',
          margin: '0.125',
          padding: '0.1',
          stroke: '0.001',
          page_size: ''
        }
      }
    end

    let(:filename) { 'makeabox.io-20200708230205-in-10.0[w]x15.0[h]x5.0[d]-0.125[t]-0.0024[k]-0.001[s].pdf' }

    before do
      expect(helper).to receive(:params).and_return(params).at_most(10).times
      helper.create_new_config
    end

    it 'generates PDF file' do
      expect(helper).to receive(:timestamp).and_return('20200708230205')
      expect(File.basename(helper.generate_pdf_filename)).to eq filename
    end
  end
end

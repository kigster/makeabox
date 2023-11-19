# frozen_string_literal: true

require 'rails_helper'
require 'makeabox/host_probe'

RSpec.describe Makeabox::HostPortProbe do
  let(:port) { 28_745 }
  let(:host) { '127.0.0.1' }

  if `which nc` =~ /nc/
    context 'verify with "nc"' do
      let(:nc) { `which nc` }
      let(:nc_command) { "nc -z -v -w30 #{host} #{port} 2>&1" }

      it 'nc should exist' do
        expect(nc).not_to be_nil
      end

      it 'is closed before the server is started' do
        expect(`#{nc_command}`).to match(/Connection refused/)
      end
    end
  end

  context 'verify using sockets' do
    subject(:probe) do
      described_class.new(host, port)
    end

    its(:open?) { is_expected.to be_falsey }
    its(:nc_open?) { is_expected.to be_falsey }

    context 'after starting a server' do
      before do
        probe.hello_server
        sleep 0.1
      end

      # Do it twice to ensure we properly close the port
      its(:open?) { is_expected.to eq "HELLO\n" }
      its(:open?) { is_expected.to eq "HELLO\n" }
    end
  end
end

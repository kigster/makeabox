require 'rails_helper'
require 'makeabox/cap/puma'

module MakeABox
  module Cap
    module Testing
      class Context
        attr_reader :current_path, :release_path, :env

        def initialize(current_path: nil,
                       release_path: nil,
                       env: {})
          @current_path = current_path
          @release_path = release_path
          @env          = env
          @string_io = StringIO.new
        end

        def execute(command)
          @string_io.puts command
        end

        def fetch(key)
          env[key]
        end

        def output
          @string_io.string
        end
      end
    end

    RSpec.describe Puma do
      let(:current_path) { '/app/makeabox/current' }
      let(:release_path) { '/app/makeabox/releases/20200701000000' }
      let(:env) { { RAILS_ENV: 'production', APP: 'makeabox' } }

      let(:context) {
        Testing::Context.new(release_path: release_path,
                             current_path: current_path,
                             env: env)
      }

      let(:command) {
        described_class.master_pid(signals: %i[USR2],
                                   context: context,
                                   command: 'echo "hello"')
      }

      context '#master_pid' do
        subject { context }
        before { command }
        its(:output) { is_expected.to match /echo "hello"/ }
      end
    end
  end
end

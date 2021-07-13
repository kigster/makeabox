# frozen_string_literal: true

module MakeABox
  module Cap
    module Puma
      def self.master_pid(context:, signals: [], command: nil)
        pid_command = 'export PID="$(/bin/ps -ef | grep [p]uma | grep -v cluster | grep makeabox | awk \'{print $2}\')"'
        context.instance_eval do
          env_setup = <<~SETUP.gsub(/\n/, '')
            set +e;
            source ~/.bashrc;
            cd "#{current_path}">/dev/null; #{' '}
            export APP="#{fetch(:application)}"; #{' '}
            export RAILS_ENV="#{fetch(:rails_env)}"
          SETUP

          signals.each do |signal|
            execute <<~BASH
              #{env_setup}
              #{pid_command}#{' '}
              if [[ -n "${PID}" ]]#{' '}
              then echo "Puma Master process detected, PID=$PID"
                   echo "Sending signal #{signal} to ${PID}"
                   kill -#{signal} ${PID} 2>/dev/null
              fi
              exit 0
            BASH
          end

          if command
            execute <<~BASH
              #{env_setup}
              #{pid_command}
              if [[ -n "${PID}" ]]; then #{command || 'true'}; fi
            BASH
          end
        end
      end
    end
  end
end

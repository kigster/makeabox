# frozen_string_literal: true

require 'ipaddr'
require 'socket'

module Makeabox
  # Class wrapping a remote hostname or an IP address
  class HostProbe
    attr_accessor :host

    # @param [String] ip_or_hostname IP address or hostname to check
    def initialize(ip_or_hostname)
      self.host =
        if ip_or_hostname =~ IPAddr::RE_IPV4ADDRLIKE
          IPAddr.new(ip_or_hostname)
        else
          ip_or_hostname
        end
    end
  end

  # A Class wrapping a pair of host/ip + port.
  class HostPortProbe < HostProbe
    attr_accessor :port

    def initialize(ip_or_hostname, port)
      super(ip_or_hostname)
      self.port = port
    end

    # Starts a TCP server on a given port that listens for a connection
    # and upon first connecting socket returns string HELLO, closes the socket, and
    # stops the thread.
    def hello_server
      server = TCPServer.new(port) # Server bind to port 2000
      Thread.new do
        client = server.accept # Wait for a client to connect
        client.puts 'HELLO'
        client.close
        server.close
      end
    end

    # Validates if a given port is open and being actively listened to
    # @return true if open, false otherwise
    def open?
      Timeout.timeout(1) do
        socket = TCPSocket.new(host.to_s, port)
        socket.read
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      ensure
        begin
          socket&.close
        rescue StandardError
          nil
        end
      end
    rescue Timeout::Error
      false
    end

    def closed?
      !open?
    end

    def nc_closed?
      `nc -z -v -w30 #{host} #{port} 2>&1` =~ /Connection refused/
    end

    def nc_open?
      !nc_closed?
    end
  end
end

# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require 'timeout'
require 'socket'

# Borrowed from Webrat and Selenium client, watches for TCP port
# liveness of the spawned server.
# @private
class TCPSocket  
  def self.wait_for_service(options)
    verbose_wait until listening_service?(options)
  end

  def self.wait_for_service_termination(options)
    verbose_wait while listening_service?(options)
  end

  def self.listening_service?(options)
    Timeout::timeout(options[:timeout] || 20) do
      begin
        socket = TCPSocket.new(options[:host], options[:port])
        socket.close unless socket.nil?
        true
      rescue Errno::ECONNREFUSED,
        Errno::EBADF           # Windows
        false
      end
    end
  end

  def self.verbose_wait
    # Removed the puts call so as not to clutter up test output.
    sleep 2
  end

  def self.wait_for_service_with_timeout(options)
    start_time = Time.now

    until listening_service?(options)
      verbose_wait

      if options[:timeout] && (Time.now > start_time + options[:timeout])
        raise SocketError.new("Socket did not open within #{options[:timeout]} seconds")
      end
    end
  end

  def self.wait_for_service_termination_with_timeout(options)
    start_time = Time.now

    while listening_service?(options)
      verbose_wait

      if options[:timeout] && (Time.now > start_time + options[:timeout])
        raise SocketError.new("Socket did not terminate within #{options[:timeout]} seconds")
      end
    end
  end
end

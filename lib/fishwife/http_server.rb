#--
# Copyright (c) 2011-2014 David Kellum
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You may
# obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#++

module Fishwife
  class HttpServer < RJack::Jetty::ServerFactory

    attr_accessor :host

    # Create the server with specified options:
    #
    # :host::
    #     String specifying the IP address to bind to (default: 0.0.0.0)
    #
    # :port::
    #     String or integer with the port to bind to (default: 9292).
    #     Jetty picks if given port 0 (and port can be read on return
    #     from start.)
    #
    # :min_threads::
    #     Minimum number of threads to keep in pool (default: 5)
    #
    # :max_threads::
    #     Maximum threads to create in pool (default: 50)
    #
    # :max_idle_time_ms::
    #     Maximum idle time for a connection in milliseconds (default: 10_000)
    #
    # :request_log_file::
    #     Request log to file name or :stderr (default: nil, no log)
    def initialize( options = {} )
      super()

      @server = nil
      @host = nil

      self.min_threads = 5
      self.max_threads = 50
      self.port = 9292

      options = Hash[ options.map { |o| [ o[0].to_s.downcase.to_sym, o[1] ] } ]

      # Translate option values from possible Strings
      [:port, :min_threads, :max_threads, :max_idle_time_ms].each do |k|
        v = options[k]
        options[k] = v.to_i if v
      end

      v = options[ :request_log_file ]
      options[ :request_log_file ] = v.to_sym if v == 'stderr'

      # Apply options as setters
      options.each do |k,v|
        setter = "#{k}=".to_sym
        send( setter, v ) if respond_to?( setter )
      end
    end

    # Start the server, given rack app to run
    def start( app )
      set_context_servlets( '/', { '/*' => RackServlet.new( app ) } )

      @server = create
      @server.start
      # Recover the server port in case 0 was given.
      self.port = @server.connectors[0].local_port

      @server
    end

    # Join with started server so main thread doesn't exit.
    def join
      @server.join if @server
    end

    # Stop the server to allow graceful shutdown
    def stop
      @server.stop if @server
    end

    def create_connectors( *args )
      super.tap do |ctrs|
        ctrs.first.host = @host if ctrs.first
      end
    end

  end
end

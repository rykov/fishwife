#--
# Copyright (c) 2011-2015 David Kellum
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

    # Create the server with specified options:
    #
    # :host::
    #     The interface to bind to (default: 0.0.0.0 -> all)
    #
    # :port::
    #     The local port to bind to, for the first connection. Jetty
    #     picks if given port 0, and first connection port can be read
    #     on return from start. (default: 9292)
    #
    # :connections::
    #     An array, or a string that will be split on '|', where each
    #     element is a connection URI String or a hash of
    #     parameters. See details below.
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
    #
    # :request_body_ram::
    #     Maximum size of request body (i.e POST) to keep in memory
    #     before resorting to a temporary file (default: 256 KiB)
    #
    # :request_body_tmpdir::
    #     Path to where request body temporary files should be created
    #     (when request_body_ram is exceeded.)  (default: Dir.tmpdir)
    #
    # :request_body_max::
    #     Maximum total size of a request body, after which the
    #     request will be rejected with status 413. This limit is
    #     provided to avoid pathologic resource exhaustion. (default: 8 MiB)
    #
    # === Options in connections
    #
    # Each member of the connections array is either a hash with
    # the following properties or an equivalent URI string:
    #
    # :scheme:: Values 'tcp' or 'ssl'
    # :host:: The local interface to bind
    #         (default: top level #host or 0.0.0.0)
    # :port:: Port number or 0 to select an available port
    #         (default: top level #port for first connection or 0)
    # :max_idle_time_ms:: See above
    # :key_store_path:: For ssl, the path to the (Java JKS) keystore
    # :key_store_password:: For ssl, the password to the keystore
    #
    # URI examples:
    #
    #  tcp://127.0.0.1
    #  ssl://0.0.0.0:8443?key_store_path=keystore&key_store_password=399as8d9
    #
    def initialize( options = {} )
      super()

      @server = nil

      self.min_threads = 5
      self.max_threads = 50
      self.port = 9292

      options = Hash[ options.map { |o| [ o[0].to_s.downcase.to_sym, o[1] ] } ]

      # Translate option values from possible Strings
      [ :port, :min_threads, :max_threads, :max_idle_time_ms,
        :request_body_ram, :request_body_max ].each do |k|
        v = options[k]
        options[k] = v.to_i if v
      end

      v = options[ :request_log_file ]
      options[ :request_log_file ] = v.to_sym if v == 'stderr'

      v = options[ :connections ]
      options[ :connections ] = v.split('|') if v.is_a?( String )

      # Split out servlet options.
      @servlet_options = {}
      [ :request_body_ram, :request_body_tmpdir, :request_body_max ].each do |k|
        @servlet_options[k] = options.delete(k)
      end

      # Apply remaining options as setters
      options.each do |k,v|
        setter = "#{k}=".to_sym
        send( setter, v ) if respond_to?( setter )
      end
    end

    # Start the server, given rack app to run
    def start( app )
      set_context_servlets( '/',
                            {'/*' => RackServlet.new(app, @servlet_options)} )

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
  end
end

module Mizuno
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

    def create_connectors
      super.each { |c| c.host = @host if @host }
    end

  end
end

require 'mizuno'

module Rack
  module Handler
    # Rack expects Rack::Handler::Mizuno via require 'rack/handler/mizuno'
    class Mizuno

      # Called by rack to run
      def self.run( app, opts = {} )
        @server = ::Mizuno::HttpServer.new( opts )
        @server.start( app )
        @server.join
      end

      # Called by rack
      def self.shutdown
        @server.stop if @server
      end

    end
  end
end

require 'fishwife'

module Rack
  module Handler
    # Rack expects Rack::Handler::Fishwife via require 'rack/handler/fishwife'
    class Fishwife

      # Called by rack to run
      def self.run( app, opts = {} )
        @server = ::Fishwife::HttpServer.new( opts )
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

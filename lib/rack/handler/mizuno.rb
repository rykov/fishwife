require 'mizuno'

module Rack
  module Handler
    # Rack expects Rack::Handler::Mizuno via require 'rack/handler/mizuno'
    class Mizuno
      Server = ::Mizuno::HttpServer

      # Called by rack to run
      def self.run( app, opts = {} )
        Server.run( app, opts )
        Server.join
      end

      # Called by rack
      def self.shutdown
        Server.stop
      end

    end
  end
end

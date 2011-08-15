require 'mizuno'

module Rack
  module Handler
    module Mizuno

      def self.run( app, opts = {} )
        ::Mizuno::HttpServer.run( app, opts )
      end

    end
  end
end

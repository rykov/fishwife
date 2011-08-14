require 'mizuno'

begin
  require 'rjack-logback'
  RJack::Logback.config_console( :stderr => true, :thread => true )
rescue LoadError => e
  require 'rjack-slf4j/simple'
end

module Rack
  module Handler
    module Mizuno

      def self.run( app, opts = {} )
        ::Mizuno::HttpServer.run( app, opts )
      end

    end
  end
end

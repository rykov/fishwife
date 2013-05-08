#--
# Copyright (c) 2011-2013 David Kellum
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

require 'fishwife'
require 'rack/server'
require 'rack/chunked'

module Rack

  class Server
    alias orig_middleware middleware

    # Override to remove Rack::Chunked middleware from defaults of any
    # environment. Rack::Chunked doesn't play nice with Jetty which
    # does its own chunking. Unfortunately rack doesn't have a better
    # way to indicate this incompatibility.
    def middleware
      mw = Hash.new { |h,k| h[k] = [] }
      orig_middleware.each do |env, wares|
        mw[ env ] = cream( wares )
      end
      mw
    end

    def cream( wares )
      wares.reject do |w|
        w == Rack::Chunked || ( w.is_a?( Array ) && w.first == Rack::Chunked )
      end
    end
  end

  # Use of `rackup` may still include Rack::Chunked given load order.
  # Override chunk as No-Op.
  class Chunked
    def initialize( app )
      @app = app
    end
    def call( env )
      @app.call( env )
    end
  end

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

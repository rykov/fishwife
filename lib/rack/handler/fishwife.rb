#--
# Copyright (c) 2011-2012 David Kellum
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

#--
# Copyright (c) 2011-2016 David Kellum
# Copyright (c) 2010-2011 Don Werve
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

require 'rubygems'
require 'bundler/setup'

# Setup logging
require 'rjack-logback'
RJack::Logback.config_console( :stderr => true, :thread => true )
RJack::Logback.root.level = RJack::Logback::DEBUG if ENV['DEBUG_LOG']

# All dependencies for testing.
require 'yaml'
require 'net/http'
require 'openssl'
require 'rack/urlmap'
require 'rack/lint'
require 'fishwife'

Thread.abort_on_exception = true

# Adjust Rack::Lint to not interfere with File body.to_path
class Rack::Lint

  def respond_to?( mth )
    if mth == :to_path
      @body.respond_to?( :to_path )
    else
      super
    end
  end

  def to_path
    @body.to_path
  end

end

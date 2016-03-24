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

require 'json'

# A tiny Rack application for testing the Fishwife webserver.  Each of
# the following paths can be used to test webserver behavior:
#
# /ping:: Always returns 200 OK.
#
# /error/:number:: Returns the HTTP status code specified in the path.
#
# /echo:: Returns a plaintext rendering of the original request.
#
# /file:: Returns a file for downloading.
#
# /push:: Publishes a message to async listeners.
#
# /pull:: Recieves messages sent via /push using async.
#
# A request to any endpoint not listed above will return a 404 error.
class TestApp
  def initialize
    @subscribers = Array.new
  end

  def call(env)
    begin
      request = Rack::Request.new(env)
      method = request.path[/^\/(\w+)/, 1]
      return(error(request, 404)) if (method.nil? or method.empty?)
      return(error(request, 404)) unless respond_to?(method.to_sym)
      send(method.to_sym, request)
    rescue => error
      puts error
      puts error.backtrace
      error(nil, 500)
    end
  end

  def ping(request)
    [ 200, { "Content-Type" => "text/plain",
        "Content-Length" => "2" }, [ "OK" ] ]
  end

  def error(request, code = nil)
    code ||= (request.path[/^\/\w+\/(\d+)/, 1] or "500")
    [ code.to_i,
      { "Content-Type" => "text/plain",
        "Content-Length" => "5" },
      [ "ERROR" ] ]
  end

  def echo(request)
    response = Rack::Response.new
    env = request.env.merge('request.params' => request.params)
    response.write(env.to_json)
    response.finish
  end

  def dcount(request)
    inp = request.env['rack.input']
    dc = inp.read.length
    inp.rewind
    dc += inp.read.length
    [ 200, {}, [ dc.to_s ] ]
  end

  def multi_headers(request)
    [ 204, { "Warning" => %w[ warn-1 warn-2 ].join( "\n" ) }, [] ]
  end

  def push(request)
    message = request.params['message']

    @subscribers.reject! do |subscriber|
      begin
        response = Rack::Response.new
        if(message.empty?)
          subscriber.call(response.finish)
          next(true)
        else
          response.write(message)
          subscriber.call(response.finish)
          next(false)
        end
      rescue java.io.IOException => error
        next(true)
      end
    end

    ping(request)
  end

  def pull(request)
    @subscribers << request.env['async.callback']
    throw(:async)
  end

  def download(request)
    file = File.new( File.dirname( __FILE__ ) + "/data/reddit-icon.png" )
    def file.to_path
      path
    end
    [ 200, { "Content-Type" => "image/png" }, file ]
  end

  def upload(request)
    data = request.params['file'][:tempfile].read
    checksum = Digest::MD5.hexdigest(Base64.decode64(data))
    response = Rack::Response.new
    response.write(checksum)
    response.finish
  end

  def frozen_response(request)
    [200, {}.freeze, [].freeze].freeze
  end
end

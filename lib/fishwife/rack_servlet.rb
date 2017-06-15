#--
# Copyright (c) 2011-2017 David Kellum
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

require 'tempfile'
require 'stringio'

# Magic loader hook -> JRubyService
require 'fishwife/JRuby'

module Fishwife
  java_import 'javax.servlet.http.HttpServlet'

  # Error raised if a request body is larger than the
  # :request_body_max option.
  class RequestBodyTooLarge < RuntimeError
  end

  # Wraps a Rack application in a Java servlet.
  #
  # Relevant documentation:
  #
  # * {Rack Specification}[http://www.rubydoc.info/github/rack/rack/file/SPEC]
  # * {Java HttpServlet}[http://docs.oracle.com/javaee/7/api/javax/servlet/http/HttpServlet.html]
  #
  class RackServlet < HttpServlet
    java_import 'java.io.FileInputStream'

    ASCII_8BIT = Encoding.find( "ASCII-8BIT" ) if defined?( Encoding )

    REQ_HIJACK_NOT_SUPPORTED = lambda do
      raise( NotImplementedError,
             'Only response hijacking is supported, not request hijacking' )
    end

    def initialize( app, opts = {} )
      super()
      @log = RJack::SLF4J[ self.class ]
      @app = app
      @request_body_ram = opts[:request_body_ram] ||      256 * 1024
      @request_body_tmpdir = opts[:request_body_tmpdir] || Dir.tmpdir
      @request_body_max = opts[:request_body_max] || 8 * 1024 * 1024
    end

    # Takes an incoming request (as a Java Servlet) and dispatches it
    # to the rack application setup via [rackup].  All this really
    # involves is translating the various bits of the Servlet API into
    # the Rack API on the way in, and translating the response back on
    # the way out.
    def service(request, response)
      # Turn the ServletRequest into a Rack env hash
      env = servlet_to_rack(request)

      # Add our own special bits to the rack environment so that Rack
      # middleware can have access to the Java internals.
      env['rack.java.servlet'] = true
      env['rack.java.servlet.request'] = request
      env['rack.java.servlet.response'] = response

      rack_response = @app.call(env)
      rack_to_servlet(rack_response, request, response)
      nil
    rescue RequestBodyTooLarge => e
      @log.warn( "On service: #{e.class.name}: #{e.message}" )
      response.sendError( 413 )
    rescue NativeException => n
      @log.warn( "On service (native): #{n.cause.to_string}" )
      raise n.cause
    rescue Exception => e
      @log.error( "On service: #{e}" )
      raise e
    ensure
      fin = env && env['fishwife.input']
      fin.close if fin
    end

    private

    # Turns a Servlet request into a Rack request hash.
    def servlet_to_rack(request)
      # The Rack request that we will pass on.
      env = Hash.new

      # Map Servlet bits to Rack bits.
      env['REQUEST_METHOD'] = request.getMethod
      qstring = request.getQueryString.to_s #or empty string
      env['QUERY_STRING'] = qstring
      env['SERVER_NAME'] = request.getServerName
      env['SERVER_PORT'] = request.getServerPort.to_s
      env['rack.version'] = Rack::VERSION
      env['rack.url_scheme'] = request.getScheme
      env['HTTP_VERSION'] = request.getProtocol
      env["SERVER_PROTOCOL"] = request.getProtocol
      env['REMOTE_ADDR'] = request.getRemoteAddr
      env['REMOTE_HOST'] = request.getRemoteHost

      # request.getPathInfo seems to be blank, so we're using the URI.
      env['REQUEST_PATH'] = request.getRequestURI
      env['PATH_INFO'] = request.getRequestURI
      env['SCRIPT_NAME'] = ""

      # Rack says URI, but it hands off a URL.
      req_uri = request.getRequestURL.to_s

      # Java chops off the query string, but a Rack application will
      # expect it, so we'll add it back if present
      req_uri << '?' << qstring unless qstring.empty?
      env['REQUEST_URI'] = req_uri

      # CONTENT_TYPE/LENGTH are handled specifically, not in headers.
      ctype = request.getContentType
      env['CONTENT_TYPE'] = ctype if ctype && !ctype.empty?
      clength = request.getContentLength
      env['CONTENT_LENGTH'] = clength.to_s if clength != -1

      # JRuby is like the matrix, only there's no spoon or fork().
      env['rack.multiprocess'] = false
      env['rack.multithread'] = true
      env['rack.run_once'] = false

      # Populate the HTTP headers.
      hn = request.getHeaderNames
      if hn.respond_to?( :each )
        hn.each do |header_name|
          header = header_name.upcase.tr('-', '_')
          next if header == 'CONTENT_TYPE' || header == 'CONTENT_LENGTH'
          env[ 'HTTP_' + header ] = request.getHeader( header_name )
        end
      else
        @log.warn( "Weird headers: [#{ hn.to_s }]" )
      end

      env['rack.input'] = env['fishwife.input'] =
        convert_input( request.input_stream, clength )

      # The output stream defaults to stderr.
      env['rack.errors'] ||= $stderr

      env['rack.hijack?'] = true
      env['rack.hijack'] = REQ_HIJACK_NOT_SUPPORTED

      # All done, hand back the Rack request.
      env
    end

    def convert_input( in_stream, clength )
      io = StringIO.new
      io.set_encoding( ASCII_8BIT )
      blen = if clength > 0
               if clength > @request_body_max
                 raise( RequestBodyTooLarge,
                        "Request body (Content-Length): " +
                        "#{clength} > #{@request_body_max}" )
               end
               if clength < 16*1024
                 clength
               else
                 16*1024
               end
             else
               0 #default/unspecified
             end

      IOUtil.read_input_stream( blen, in_stream ) do |sbuf|
        fsize = io.pos + sbuf.bytesize
        if fsize > @request_body_max
          raise( RequestBodyTooLarge,
                 "Request body (read): #{fsize} > #{@request_body_max}" )
        end
        if io.is_a?( StringIO ) && fsize > @request_body_ram
          tmp = Tempfile.new( 'fishwife_req_body', @request_body_tmpdir )
          tmp.unlink
          tmp.binmode
          tmp.set_encoding( ASCII_8BIT )
          tmp.write( io.string )
          io = tmp
        end
        io.write( sbuf )
      end

      io.rewind
      io
    end

    # Turns a Rack response into a Servlet response.
    #
    # Note that keep-alive *only* happens if we get either a pathname
    # (because we can find the length ourselves), or if we get a
    # Content-Length header as part of the response.  While we can
    # readily buffer the response object to figure out how long it is,
    # we have no guarantee that we aren't going to be buffering
    # something *huge*.
    #
    # http://docstore.mik.ua/orelly/java-ent/servlet/ch05_03.htm
    def rack_to_servlet(rack_response, request, response)
      # Split apart the Rack response.
      status, headers, body = rack_response

      # Set the HTTP status code.
      response.setStatus(status.to_i)

      response_hijack_callback = headers['rack.hijack']

      # Add all the result headers.
      headers.each do |h, v|
        case h
        when 'rack.hijack'
          # ignore
        when 'Content-Length'
          # Did we get a Content-Length header?
          response.setContentLength(v.to_i) if v
        when 'Content-Type'
          # Did we get a Content-Type header?
          response.setContentType(v) if v
        else
          v.split("\n").each { |val| response.addHeader(h, val) }
        end
      end

      if response_hijack_callback
        hijack_io = HijackIo.new(request.start_async)
        response_hijack_callback.call(hijack_io)
      else
        output = response.getOutputStream

        if body.respond_to?( :to_path )

          path = body.to_path

          unless headers['Content-Length']
            response.setContentLength( File.size( path ) )
          end

          # FIXME: Support ranges?

          IOUtil.write_file( path, output )
        else
          IOUtil.write_body( body, output )
        end

        # Close the body if we're supposed to.
        body.close if body.respond_to?(:close)

        # All done.
        output.close
      end
    end
  end
end

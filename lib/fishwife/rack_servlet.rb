#--
# Copyright (c) 2011-2012 David Kellum
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

#
# Wraps a Rack application in a Java servlet.
#
# Relevant documentation:
#
#     http://rack.rubyforge.org/doc/SPEC.html
#     http://java.sun.com/j2ee/sdk_1.3/techdocs/api/javax
#         /servlet/http/HttpServlet.html
#
module Fishwife
  java_import 'javax.servlet.http.HttpServlet'

  class RackServlet < HttpServlet
    java_import 'java.io.FileInputStream'
    java_import 'org.eclipse.jetty.continuation.ContinuationSupport'

    ASCII_8BIT = Encoding.find( "ASCII-8BIT" ) if defined?( Encoding )

    def initialize( app )
      super()
      @log = RJack::SLF4J[ self.class ]
      @app = app
    end

    # Takes an incoming request (as a Java Servlet) and dispatches it
    # to the rack application setup via [rackup].  All this really
    # involves is translating the various bits of the Servlet API into
    # the Rack API on the way in, and translating the response back on
    # the way out.
    #
    # Also, we implement a common extension to the Rack api for
    # asynchronous request processing.  We supply an 'async.callback'
    # parameter in env to the Rack application.  If we catch an :async
    # symbol thrown by the app, we initiate a Jetty continuation.
    #
    # When 'async.callback' gets a response with empty headers and an
    # empty body, we declare the async response finished.
    def service(request, response)
      # Turn the ServletRequest into a Rack env hash
      env = servlet_to_rack(request)

      # Handle asynchronous responses via Servlet continuations.
      continuation = ContinuationSupport.getContinuation(request)

      # If this is an expired connection, do nothing.
      return if continuation.isExpired

      # We should never be re-dispatched.
      raise("Request re-dispatched.") unless continuation.isInitial

      # Add our own special bits to the rack environment so that Rack
      # middleware can have access to the Java internals.
      env['rack.java.servlet'] = true
      env['rack.java.servlet.request'] = request
      env['rack.java.servlet.response'] = response
      env['rack.java.servlet.continuation'] = continuation

      # Add an callback that can be used to add results to the
      # response asynchronously.
      env['async.callback'] = lambda do |rack_response|
        servlet_response = continuation.getServletResponse
        rack_to_servlet(rack_response, servlet_response) and
          continuation.complete
      end

      # Execute the Rack request.
      catch(:async) do
        rack_response = @app.call(env)

        # For apps that don't throw :async.
        unless(rack_response[0] == -1)
          # Nope, nothing asynchronous here.
          rack_to_servlet(rack_response, response)
          return
        end
      end

      # If we got here, this is a continuation.
      continuation.suspend(response)

    rescue NativeException => n
      @log.warn( "On service (native): #{n.cause.to_string}" )
      raise n.cause
    rescue Exception => e
      @log.error( "On service: #{e}" )
      raise e
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
      req_uri = request.getRequestURL.toString

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

      # The input stream is a wrapper around the Java InputStream.
      input = request.getInputStream.to_io.binmode
      input.set_encoding( ASCII_8BIT ) if input.respond_to?( :set_encoding )
      env['rack.input'] = input

      # The output stream defaults to stderr.
      env['rack.errors'] ||= $stderr

      # All done, hand back the Rack request.
      env
    end

    # Turns a Rack response into a Servlet response; can be called
    # multiple times.  Returns true if this is the full request (either
    # a synchronous request or the last part of an async request),
    # false otherwise.
    #
    # Note that keep-alive *only* happens if we get either a pathname
    # (because we can find the length ourselves), or if we get a
    # Content-Length header as part of the response.  While we can
    # readily buffer the response object to figure out how long it is,
    # we have no guarantee that we aren't going to be buffering
    # something *huge*.
    #
    # http://docstore.mik.ua/orelly/java-ent/servlet/ch05_03.htm
    def rack_to_servlet(rack_response, response)
      # Split apart the Rack response.
      status, headers, body = rack_response

      # We assume the request is finished if we got empty headers,
      # an empty body, and we have a committed response.
      finished = ( headers.empty? and
                   body.respond_to?(:empty?) and body.empty?)
      return(true) if (finished and response.isCommitted)

      # No need to send headers again if we've already shipped data
      # out on an async request.
      unless(response.isCommitted)
        # Set the HTTP status code.
        response.setStatus(status.to_i)

        # Did we get a Content-Length header?
        content_length = headers.delete('Content-Length')
        response.setContentLength(content_length.to_i) if content_length

        # Did we get a Content-Type header?
        content_type = headers.delete('Content-Type')
        response.setContentType(content_type) if content_type

        # Add all the result headers.
        headers.each do |h, v|
          v.split("\n").each { |val| response.addHeader(h, val) }
        end
      end

      # How else would we write output?
      output = response.getOutputStream

      # Turn the body into something nice and Java-y.
      if(body.respond_to?(:to_path))
        # We've been told to serve a file; use FileInputStream to
        # stream the file directly to the servlet, because this is a
        # lot faster than doing it with Ruby.
        file = java.io.File.new(body.to_path)

        # We set the content-length so we can use Keep-Alive, unless
        # this is an async request.
        response.setContentLength(file.length) unless content_length

        # Stream the file directly.
        buffer = Java::byte[4096].new
        input_stream = FileInputStream.new(file)
        while((count = input_stream.read(buffer)) != -1)
          output.write(buffer, 0, count)
        end
        input_stream.close
      else
        body.each { |l| output.write(l.to_java_bytes) }
      end

      # Close the body if we're supposed to.
      body.close if body.respond_to?(:close)

      # All done.
      output.flush
      false
    end
  end
end

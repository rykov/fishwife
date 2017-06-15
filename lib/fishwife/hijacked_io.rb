module Fishwife

  # Wraps a Java Servlets
  # {AsyncContext}[http://docs.oracle.com/javaee/7/api/javax/servlet/AsyncContext.html]
  # as a ruby ::IO-like class for use in \Rack response (after headers)
  # {Hijacking}[http://www.rubydoc.info/github/rack/rack/file/SPEC#Hijacking].
  #
  # This currently supports only (blocking) #write, #flush, and
  # #close. Other methods raise NotImplementedError.
  class HijackedIO
    def initialize(async_context)
      @async_context = async_context
      @closed = false
    end

    # Writes the given str to the #output_stream as bytes. If str is
    # not a ruby String, it will be converted using Object#to_s.
    # Returns the bytesize of the String (Java's OutputStream#write is
    # never partial).
    def write(str)
      str = str.to_s
      IOUtil.write(str, out_stream)
      str.bytesize
    end

    # Flushes the underlying #output_stream and returns self.
    def flush
      out_stream.flush
      self
    end

    # Calls complete on the underlying AsyncContext. Subsequent calls
    # after the first are ignored.
    def close
      if !@closed
        @async_context.complete
        @closed = true
      end
      nil
    end

    alias_method :close_write, :close

    # Return true if #close has been called.
    def closed?
      @closed
    end

    # Raises NotImplementedError.
    def read(*)
      raise NotImplementedError, "##{__method__} on hijacked IO is not supported"
    end

    # Raises NotImplementedError.
    def read_nonblock(*)
      raise NotImplementedError, "##{__method__} on hijacked IO is not supported"
    end

    # Raises NotImplementedError.
    def write_nonblock(*)
      raise NotImplementedError, "##{__method__} on hijacked IO is not supported"
    end

    # Raises NotImplementedError.
    def close_read
      raise NotImplementedError, "##{__method__} on hijacked IO is not supported"
    end

    private

    def out_stream
      @out_stream ||= @async_context.response.output_stream
    end

  end
end

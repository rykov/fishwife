module Fishwife
  class HijackIo
    def initialize(async_context)
      @async_context = async_context
      @closed = false
    end

    def write(str)
      IOUtil.write(str, @async_context.response.output_stream)
      str.bytesize
    end

    def flush
      @async_context.response.output_stream.flush
      self
    end

    def close
      @async_context.complete
      @closed = true
      nil
    end
    alias_method :close_write, :close

    def closed?
      @closed
    end

    def read(*)
      raise NotImplementedError, "##{__method__} on hijacked IO is not supported"
    end

    def read_nonblock(*)
      raise NotImplementedError, "##{__method__} on hijacked IO is not supported"
    end

    def write_nonblock(*)
      raise NotImplementedError, "##{__method__} on hijacked IO is not supported"
    end

    def close_read
      raise NotImplementedError, "##{__method__} on hijacked IO is not supported"
    end
  end
end

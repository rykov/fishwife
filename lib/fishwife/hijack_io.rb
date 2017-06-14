module Fishwife
  class HijackIo
    def initialize(async_context)
      @async_context = async_context
      @closed = false
    end

    def write(str)
      str = str.to_s
      IOUtil.write(str, out_stream)
      str.bytesize
    end

    def flush
      out_stream.flush
      self
    end

    def close
      if !@closed
        @async_context.complete
        @closed = true
      end
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

    private

    def out_stream
      @out_stream ||= @async_context.response.output_stream
    end

  end
end

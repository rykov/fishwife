module Fishwife
  class HijackIo
    def initialize(async_context)
      @async_context = async_context
    end

    def write(str)
      IOUtil.write(str, @async_context.response.output_stream)
    end

    def flush
      @async_context.response.output_stream.flush
    end

    def close
      @async_context.complete
    end

    def close_write(str)
      write(str)
      close
    end

    def closed?
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

module Fishwife
  class HijackIo
    class WriteWouldBlock < Errno::EWOULDBLOCK
      include IO::WaitWritable
    end

    def initialize(async_context)
      @async_context = async_context
    end

    def write(str)
      @async_context.response.output_stream.print(str)
    end

    def write_nonblock(str)
      output_stream = @async_context.response.output_stream
      if output_stream.ready?
        output_stream.print(str)
      else
        raise WriteWouldBlock
      end
    end

    def flush
      @async_context.response.writer.flush
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
      raise NotImplementedError, '##{__method__} on hijacked IO is not supported'
    end

    def read_nonblock(*)
      raise NotImplementedError, '##{__method__} on hijacked IO is not supported'
    end

    def close_read
      raise NotImplementedError, '##{__method__} on hijacked IO is not supported'
    end
  end
end

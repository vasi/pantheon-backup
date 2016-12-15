class Threadpool
  def initialize(size, logger)
    @size = size
    @queue = Queue.new
    @threads = []
    @mutex = Mutex.new
    @cv = ConditionVariable.new
    @todo = 0
    size.times do
      @threads << Thread.new do
        while c = @queue.pop
          begin
            c[]
          rescue => e
            logger.warn('Exception in pool: ' + e.message)
            logger.warn(e.backtrace.join("\n"))
          end
          @mutex.synchronize do
            @todo -= 1
            @cv.signal if @todo == 0
          end
        end
      end
    end
  end

  def run(&block)
    @mutex.synchronize { @todo += 1 }
    @queue << block
  end

  def wait
    @mutex.synchronize { @cv.wait(@mutex) }
    @size.times { @queue << nil }
    @threads.each { |t| t.join }
  end
end

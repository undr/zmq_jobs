require 'zmq_jobs'
class TestWorker < ZmqJobs::Worker::Base
  def execute message
    logger.info 'Start execute job'
    logger.info message
    sleep 4
    logger.info 'Finished execute job'
  end
  
  def metric_store_callback
    logger.info(@metric.to_hash)
  end
end

TestWorker.cmd(ARGV) if $0 == __FILE__

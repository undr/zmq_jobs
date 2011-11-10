require 'zmq_jobs'
class Default < ZmqJobs::Worker::Base
  def execute message
    logger.info 'Start execute job'
    logger.info message
    sleep 4
    logger.info 'Finished execute job'
  end
end

Default.cmd(ARGV) if $0 == __FILE__
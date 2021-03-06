module ZmqJobs
  module Worker
    class Base
      include ActiveSupport::Callbacks
      
      define_callbacks :start, :stop, :execute
      attr_reader :options
      set_callback :execute, :around, :metric_behaviour
      set_callback :stop, :before, :metric_store, :if => lambda{profile?}
      
      class << self
        def cmd args
          count = args[2].to_i || 0
          options = {}
          options['hosts'] = args[0] if args[0]
          options['ports'] = (args[1].to_i..(args[1].to_i + count)).to_a if args[1]
          options['iothreads'] = args[3].to_i if args[3]
          start(options)
        end
        
        def start options
          new(options).start
        end
      end
      
      def initialize options={}
        @debug = options.delete('debug') || false
        @profile = options.delete('profile') || false
        @options = options
        @metric = Metric.new(options['metric'] || {}) if profile?
      end
      
      def start
        trap('TERM'){stop;Process.exit}
        trap('INT'){stop;Process.exit}
        logger.info "#{self.class} is starting ..."
        logger.debug 'Debug mode' if debug?
        
        run_callbacks :start do
          subscriber.run do |socket|
            message = socket.recv
            execute_job message if message
          end
        end
      end
      
      def stop
        logger.info "Exiting..."
        run_callbacks :stop do
          subscriber.stop
          #subscriber.terminate
        end
      end
      
      def execute_job message
        @message = message
        
        run_callbacks :execute do
          begin
            execute(message)
          rescue => e
            error_callback(e)
            #raise e
          end
        end
        @message = nil
      end
      
      def subscriber
        @subscriber ||= Socket::Sub.new(options)
      end
      
      def logger
        ::ZmqJobs.logger
      end
      
      def debug?
        !!@debug
      end
      
      def profile?
        !!@profile
      end
      
      def metric_behaviour
        if profile?
          idle_time = @metric.timer(:idle).stop!
          @metric.timer(:execute).start!
          @metric.counter(:message_size) << @message.size
        end
        
        if debug?
          logger.debug("-" * 10)
          logger.debug "Start execute message..."
          if profile?
            logger.debug "Idle time: #{idle_time.humanize(4)} sec."
            logger.debug "Message size: #{@message.size.humanize} Byte"
          end
        end
        
        yield
        
      ensure
        if profile?
          execute_time = @metric.timer(:execute).stop!
          @metric.timer(:idle).start!
        end
        
        if debug?
          if profile?
            logger.debug "Duration: #{execute_time} sec."
          end
          logger.debug "Stop execute message"
          logger.debug("-" * 10)
        end
        
        if profile? && @metric.store_time?
          logger.debug 'Store metrics' if debug?
          metric_store
        end
      end
      
      def metric_store
        @metric.store(self)
      end
      
      def error_callback exception
        logger.warn format_exception_message(exception)
      end
      
      def format_exception_message exception
<<-MESSAGE
Execution error: #{exception} - #{exception.message}
  #{exception.backtrace[0..10].join("\n  ")}
MESSAGE
      end
    end
  end
end 

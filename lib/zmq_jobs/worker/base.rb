module ZmqJobs
  module Worker
    class Base
      include ActiveSupport::Callbacks
      define_callbacks :start, :stop, :execute
      attr_reader :options
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
        @options = options
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
        run_callbacks :execute do
          debug_execute do
            @idle_time ||= Time.now
            time = Time.now
            logger.debug "Start execute message (Idle time: #{time - @idle_time}sec)..."
          end
          execute(message)
          debug_execute do
            # TODO: Size: #{message.size.kilobytes}Kb
            logger.debug "Stop execute message...Duration: #{Time.now - time}sec."
            @idle_time = Time.now
          end
        end
      rescue => e
        logger.warn format_exception_message(e)
        #raise e
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
      
      def debug_execute
        yield if debug?
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

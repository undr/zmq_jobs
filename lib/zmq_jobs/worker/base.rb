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
        @options = options
      end
      
      def start
        trap('TERM'){stop}
        trap('INT'){stop}
        logger.info "#{self.class} is starting ..."
        run_callbacks :start do
          subscriber.run do |socket|
            message = socket.recv(message)
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
          execute(message)
        end
      rescue => e
        logger.warn format_exception_message(e)
        raise e
      end
      
      def subscriber
        @subscriber ||= Socket::Sub.new(options)
      end
      
      def logger
        ::ZmqJobs.logger
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

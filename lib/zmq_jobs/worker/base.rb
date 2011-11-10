module ZmqJobs
  module Worker
    class Base
      attr_reader :options
      class << self
        def cmd args
          options = {
            'hosts' => [args[0]],
            'ports' => (args[1]..(args[2] || args[1])).to_a
          }
          options['iothreads'] = args[3] if args[3]
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
        
        subscriber.run do |socket|
          message = ''
          rc = socket.recv_string(message, ZMQ::NOBLOCK)
          if ZMQ::Util.resultcode_ok?(rc)
            #message = BSON.deserialize(bson)
            execute_job message
          end
        end
        
        logger.info "#{self.class} has stopped"
      end
      
      def stop
        subscriber.stop
        #subscriber.terminate
      end
      
      def execute_job message
        execute(message)
      end
      
      def subscriber
        @subscriber ||= Socket::Sub.new(options)
      end
      
      def logger
        ::ZmqJobs.logger
      end
    end
  end
end 

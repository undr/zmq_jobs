module ZmqJobs
  class Device
    class << self
      def start options
        new(options).start
      end
    end
    
    attr_reader :options, :device
    
    def initialize options
      @options = options.assert_valid_keys('iothreads', 'frontend', 'backend')
    end
    
    def context
      @context ||= ZMQ::Context.create(options['iothreads'])
    end
    
    def start
      trap('TERM'){stop;Process.exit}
      trap('INT'){stop;Process.exit}
      logger.info "#{self.class} is starting ..."
      start_device
    end
    
    def stop
      frontend.disconnect
      backend.disconnect
      #context.terminate
      logger.info 'Exiting...'
    end
    
    def frontend
      @frontent ||= create_frontend
    end
    
    def backend
      @backend ||= create_backend
    end
    
    def create_frontend
    end
    
    def create_backend
    end
    
    protected
    def start_device
    end
    
    def frontend_options
      options['frontend'].
        assert_valid_keys('hosts', 'ports', 'subscribe', 'linger')
    end
    
    def backend_options
      options['backend'].
        assert_valid_keys('hosts', 'ports', 'linger')
    end
    
    def logger
      ::ZmqJobs.logger
    end
  end
end
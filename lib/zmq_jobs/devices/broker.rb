module ZmqJobs
  class Broker < Device
    protected
    def start_device
      @device = ZMQ::Device.new(ZMQ::FORWARDER, frontend.socket, backend.socket)
    end
    
    def create_frontend
      config = frontend_options
      config['context'] = context
      Socket::Sub.new(config).connect
    end
    
    def create_backend
      config = backend_options
      config['context'] = context
      Socket::Pub.new(config).connect
    end
  end
end

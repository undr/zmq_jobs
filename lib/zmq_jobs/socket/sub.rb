module ZmqJobs
  module Socket
    class Sub < Base
      def initialize options={}
        super(options)
        @socket = @context.socket(ZMQ::SUB)
        assert(socket.setsockopt(ZMQ::LINGER, self.options['linger'])) if self.options['linger']
        assert(socket.setsockopt(ZMQ::SUBSCRIBE, self.options['subscribe'])) if self.options['subscribe']
      end

      def create_link url
        socket.connect(url).tap do
          ::ZmqJobs.logger.info "Subscriber have started at #{url}"
        end
      end

      protected
      def default_options
        {
          'linger' => 0,
          'subscribe' => '',
          'hosts' => ['127.0.0.1'],
          'ports' => [2200]
        }
      end
    end
  end
end
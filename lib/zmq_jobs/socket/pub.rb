module ZmqJobs
  module Socket
    class Pub < Base
      def initialize options={}
        super(options)
        @socket = @context.socket(ZMQ::PUB)
        assert(socket.setsockopt(ZMQ::LINGER, self.options['linger'])) if self.options['linger']
      end

      def create_link url
        socket.bind(url).tap do
          sleep 1
          ::ZmqJobs.logger.info "Publisher have started at #{url}"
        end
      end

      private
      def hosts
        options['hosts'].is_a?(Array) ? [options['hosts'].first] : [options['hosts']]
      end

      def ports
        options['ports'].is_a?(Array) ? [options['ports'].first] : [options['ports']]
      end

      def default_options
        {
          'linger' => nil
        }
      end
    end
  end
end

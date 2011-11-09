module ZmqJobs
  module Socket
    class Pub < Base
      def initialize options={}
        super(options)
        @socket = @context.socket(ZMQ::PUB)
      end

      def create_link url
        ::ZmqJobs.logger.info "Publisher have started at #{url}"
        socket.bind(url)
      end

      private
      def hosts
        options['host'].is_a?(Array) ? [options['host'].first] : [options['host']]
      end

      def ports
        options['port'].is_a?(Array) ? [options['port'].first] : [options['port']]
      end

      def default_options
        {
          'host' => '*',
          'port' => 2200
        }
      end
    end
  end
end

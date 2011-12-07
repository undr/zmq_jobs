module ZmqJobs
  module Socket
    Error = Class.new(StandardError)
    class Base
      attr_reader :socket, :options
      
      def initialize options={}
        iothreads = options['iothreads'] ? options['iothreads'].to_i : 1
        @context = options.delete('context') || ZMQ::Context.create(iothreads)
        raise Error.new('Can not create context') unless @context
        @options = build_default_options.merge(options)
        @socket = @context.socket(ZMQ::PUB)
        @running = false
      end
      
      def create_link url
      end
      
      def connect
        urls.each{|url|assert(create_link(url))}
        @connected = true
        self
      end
      
      def disconnect
        socket.close if connected?
        @connected = false
        self
      end
      
      def run
        @running = true
        connect
        
        loop do
          yield self
          break unless running?
        end
        
        self
      end
      
      def stop
        @running = false
        disconnect
      end
      
      def terminate
        @context.terminate if @context && @context.respond_to?(:terminate)
      end
      
      def running?
        !!@running
      end
      
      def connected?
        !!@connected
      end
      
      def send message
        assert(socket.send_string(message))
      end
      
      def recv
        message = ''
        rc = socket.recv_string(message, ZMQ::NOBLOCK)
        return message if ZMQ::Util.resultcode_ok?(rc)
      end
      
      protected
      def assert(rc)
        raise Error.new(
          "Operation failed, errno [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
        ) unless ZMQ::Util.resultcode_ok?(rc)
      end
      
      def urls
        u = []
        hosts.each do |host|
          ports.each do |port|
            u << "tcp://#{host}:#{port}"
          end
        end
        u
      end
      
      def hosts
        options['hosts'].is_a?(Array) ? options['hosts'] : [options['hosts']]
      end
      
      def ports
        options['ports'].is_a?(Array) ? options['ports'] : [options['ports']]
      end
      
      def build_default_options
        {
          'linger' => 0,
          'hosts' => '*',
          'ports' => 2200
        }.merge(default_options).
        delete_if{|k,v|v.nil?}
      end
      
      def default_options
        {}
      end
    end
  end
end
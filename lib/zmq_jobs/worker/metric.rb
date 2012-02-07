module ZmqJobs
  module Worker
    class Metric
      class Value
        attr_reader :count, :max, :min, :current
        
        def initialize
          reset!
        end
        
        def average
          return 0 if count == 0
          @sum / count
        end
        
        def add value
          @current = value
          @sum += value
          @count +=1
          @min = [min, value].compact.min
          @max = [max, value].compact.max
          value
        end
        
        alias_method :<<, :add
        
        def reset!
          @current = nil
          @sum = 0
          @count = 0
          @min = nil
          @max = nil
        end
        
        def to_hash
          {
            :average => average,
            :max => max,
            :min => min,
            :count => count
          }
        end
      end
      
      class Timer < Value
        def start!
          @current = nil
          @timer = Time.now
        end
        
        def stop!
          if @timer
            add(Time.now - @timer)
          else
            0
          end
        end
        
        def measure
          start!
          yield
          stop!
        end
      end
      
      attr_reader :options
      
      def initialize options={}
        reset_start_timestamp!
        reset!
        @options = options
      end
      
      def reset!
        @values = {}
      end
      
      def timer name
        name = name.to_sym
        @values[name] ||= Timer.new
        @values[name]
      end
      
      def counter name
        name = name.to_sym
        @values[name] ||= Value.new
        @values[name]
      end
      
      def store_time?
        Time.now.utc.to_i - @start_timestamp > period
      end
      
      def store worker
        worker.metric_store_callback if worker.respond_to?(:metric_store_callback)
        reset_start_timestamp!
        reset!
      end
      
      def reset_start_timestamp!
        @start_timestamp = Time.now.utc.to_i
      end
      
      def to_hash
        @values.inject({}){|result, (key,metric)|
          result.merge(key => metric.to_hash)
        }.merge(:start => Time.at(@start_timestamp).utc, :finish => Time.now.utc)
      end
      
      private
      def period
        (options['period'] || 600).to_i
      end
    end
  end
end

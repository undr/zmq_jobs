require 'optparse'
require 'daemons'
require 'yaml'

module ZmqJobs
  class Command
    attr_reader :daemonize, :monitor, :config_file, :execute_dir, :options
    DEVICES = {'broker' => Broker, 'balancer' => Balancer}
    
    def self.define_properties options
      options.each do |property, value|
        define_method(property.to_sym) do |*args|
          value
        end
      end
    end
    
    def initialize(args)
      @demonize = false
      @monitor = false
      @execute_dir = Dir.pwd
      @pid_dir = './tmp'
      @config_file = './config/zmq_jobs.yml'
      @options = read_config_file
      
      if args.empty?
        puts opts_parser
        exit 1
      else
        @args = opts_parser.parse!(args)
      end
    end
    
    def start
      start_daemon(type, daemon_config(type))
    end
    
    protected
    def opts_parser
      opts_parser_builder
    end
    
    def opts_parser_builder
      OptionParser.new do |opts|
        opts.banner = opts_banner
        opts.separator ''
        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('-m', '--monitor', 'Start monitor process.') do
          @monitor = true
        end
        opts.on('-d', '--daemonize', "Daemonize the #{type} process") do
          @daemonize = true
        end
        opts.on('-c CONFIG', '--config CONFIG', "Use config file, default: #{config_file}") do |config|
          @config_file = config
        end
        yield opts if block_given?
      end
    end
    
    def opts_banner
      "Usage: #{type} <start|stop|restart> [options]"
    end
  
    def start_daemon daemon_name, config
      return false unless config
      Daemons.run_proc(
        daemon_name, 
        {
          :multiple => false,
          :dir_mode => :normal,
          :monitor => monitor,
          :ARGV => @args,
          :ontop => !daemonize
        }
      ) do
        daemon_class(daemon_name).new(config).start
      end
      true
    end
    
    def read_config_file
      YAML.load_file(File.expand_path(config_file, execute_dir))
    end
    
    def daemon_config name
      options[name] || (
        ::ZmqJobs.logger.info("#{type.capitalize} '#{name}' not found in config file") and 
          return false
      )
    end
  end
  
  class BrokerCommand < Command
    define_properties :type => 'broker', :daemon_class => Broker
  end
  
  class BalancerCommand < Command
    define_properties :type => 'balancer', :daemon_class => Balancer
  end
  
  class WorkerCommand < Command
    define_properties :type => 'worker'
    
    def start
      raise ArgumentError.new(
        'You do not have any workers to start'
      ) if workers_to_start.size < 1
      
      raise ArgumentError.new(
        'You can not start more then one worker without -d option'
      ) if workers_to_start.size > 1 && !daemonize
      
      success = workers_to_start.map{|worker|
        preload_worker_class(daemon_classname(worker))
        start_daemon(worker, daemon_config(worker))
      }.inject(&:'&&')
      
      ::ZmqJobs.logger.info('One or more workers do not started') unless success
    end
    
    protected
    def preload_worker_class classname
      worker_class_dir = File.expand_path(options['workers_dir'], execute_dir)
      Kernel.require(
        "#{worker_class_dir}/#{ActiveSupport::Inflector.underscore(classname)}"
      ) unless Kernel.const_defined?(classname)
    end
    
    def opts_parser
      opts_parser_builder do |opts|
        opts.on('-w', '--workers LIST', 'Workers which have to run.') do |workers|
          @workers = workers.split(' ')
        end
      end
    end
    
    def daemon_config name
      options['workers'][name] || (
        ::ZmqJobs.logger.info("#{type.capitalize} '#{name}' not found in config file") and 
          return nil
      )
    end
    
    def daemon_class name=nil
      ActiveSupport::Inflector.constantize(daemon_classname(name))
    end
    
    def daemon_classname name
      ActiveSupport::Inflector.camelize(name, true)
    end
    
    def all_workers
      options['workers'].keys
    end
    
    def workers_to_start
      @workers_to_start ||= if !@workers || @workers.empty?
        all_workers
      else
        @workers.select{|w|all_workers.includes?(w)}
      end
    end
  end
end

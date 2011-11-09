require 'optparse'
require 'daemons'
require 'yaml'

module ZmqJobs
  class Command
    attr_reader :daemonize, :monitor, :config_file, :execute_dir, :options
    DEVICES = {'broker' => Broker, 'balancer' => Balancer}
    
    def initialize(args)
      @demonize = false
      @monitor = false
      @execute_dir = Dir.pwd
      @pid_dir = './tmp'
      @config_file = './config/zmq_jobs.yml'
      @options = read_config_file
      
      self.init if self.respond_to?(:init)
      
      if args.empty?
        puts opts_parser
        exit 1
      else
        @args = opts_parser.parse!(args)
      end
    end
    
    def start
      Kernel.require File.expand_path './zmq_jobs/devices/broker', File.dirname(__FILE__)
      Kernel.require File.expand_path './zmq_jobs/devices/balancer', File.dirname(__FILE__)
      start_daemon(name, daemon_config(name))
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
        opts.on('-d', '--daemonize', "Daemonize the #{name} process") do
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
      return config unless config
      
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
    
    def name
      type
    end
    
    def daemon_config name
      options[name] || (
        ::ZmqJobs.logger.info("#{type.capitalize} '#{name}' not found in config file") and 
          return false
      ).tap{|h|h.symbolize_keys}
    end
    
    def daemon_class name
      ActiveSupport::Inflector.constantize(daemon_classname(name))
    end
    
    def daemon_classname name
      ActiveSupport::Inflector.camelize(name, true)
    end
  end
  
  class BrokerCommand < Command
    def type
      'broker'
    end
    
    def daemon_class name
      Broker
    end
  end
  
  class WorkerCommand < Command
    def type
      'worker'
    end
    
    def start
      raise ArgumentError.new(
        'You have to pass workers list into command (Use -w or --workers options)'
      ) if !@workers || @workers.empty?
      raise ArgumentError.new(
        'You can not start more then one worker without -d option'
      ) if @workers.size > 1 && !daemonize
      
      success = @workers.map{|worker|
        config = daemon_config(worker)
        preload_worker_class(daemon_classname(worker)) if config
        config ? start_daemon(worker, config) : false
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
          return false
      )
    end
  end
end

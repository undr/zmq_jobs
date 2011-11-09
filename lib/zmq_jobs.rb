require 'rubygems'
require 'bundler'
Bundler.setup :default, (ENV['RACK_ENV'] || 'development')
require 'yaml'
require 'active_support'
require 'active_support/core_ext/hash/keys'
require 'ffi-rzmq'
require 'logger'

require 'pp'

module ZmqJobs
  extend self
  extend ActiveSupport::Autoload
  
  autoload_under 'devices' do
    autoload :Device
    
    eager_autoload do
      autoload :Balancer
      autoload :Broker
    end
  end
  
  module Worker
    extend ActiveSupport::Autoload
    
    autoload :Base
  end
    
  module Socket
    extend ActiveSupport::Autoload
    
    autoload :Base
    autoload :Pub
    autoload :Sub
  end
  
  def logger
    @logger = default_logger unless defined?(@logger)
    @logger
  end

  def logger=(logger)
    case logger
      when Logger then @logger = logger
      when false, nil then @logger = nil
    end
  end
  
  protected
  def default_logger
    defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : ::Logger.new($stdout)
  end
end

require 'command'

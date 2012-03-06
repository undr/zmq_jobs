require 'rubygems'
require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || 'development')
require 'yaml'
require 'active_support'
require 'active_support/core_ext/hash/keys'
require 'ffi-rzmq'
require 'logger'

module ZmqJobs
  extend self
  extend ActiveSupport::Autoload
  
  autoload_under 'devices' do
    autoload :Device
    autoload :Balancer
    autoload :Broker
  end
  
  module Worker
    extend ActiveSupport::Autoload
    
    autoload :Base
    autoload :Metric
  end
    
  module Socket
    extend ActiveSupport::Autoload
    
    autoload :Base
    autoload :Pub
    autoload :Sub
  end
  
  module CoreExt
    extend ActiveSupport::Autoload
    
    autoload :Number
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
  
  def env
    return Rails.env if defined?(Rails)
    return Sinatra::Base.environment.to_s if defined?(Sinatra)
    ENV["RACK_ENV"] || ENV["ZMQ_ENV"] || 'development'
  end
  
  def root
    @root ||= Pathname.new(File.expand_path('../../', __FILE__))
  end
  
  protected
  def default_logger
    defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : ::Logger.new($stdout)
  end
end

require 'command'

require 'rails/railties' if defined?(Rails)


class Numeric
  include ZmqJobs::CoreExt::Number
end
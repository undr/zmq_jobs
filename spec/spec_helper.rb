$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
ENV['ZMQ_ENV'] = 'test'
require "rspec"
require 'zmq_jobs'

RSpec.configure do |config|
  config.mock_with :rspec
end

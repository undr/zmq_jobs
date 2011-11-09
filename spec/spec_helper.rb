$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rspec"
require 'zmq_jobs'

Spec::Runner.configure do |config|
  config.mock_with :rspec
end

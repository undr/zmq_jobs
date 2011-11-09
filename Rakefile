require 'rake'
require 'rdoc/task'
require 'rspec/core/rake_task'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'zmq_jobs'

task :build do
  system "gem build zmq_jobs.gemspec"
end

task :install => :build do
  system "sudo gem install zmq_jobs-#{ZmqJobs::VERSION}.gem"
end

task :release => :build do
  system "gem push zmq_jobs-#{ZmqJobs::VERSION}.gem"
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

task :default => ["spec"]

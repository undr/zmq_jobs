# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "zmq_jobs/version"

Gem::Specification.new do |s|
  s.name        = "zmq_jobs"
  s.version     = ZmqJobs::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Undr"]
  s.email       = ["undr@yandex.ru"]
  s.homepage    = "http://github.com/undr/zmq_jobs"
  s.summary     = %q{ZeroMQ-based queue system for background job}
  s.description = %q{ZeroMQ-based queue system for background job}

  s.rubyforge_project = "zmq_jobs"
  
  s.add_development_dependency "rspec", ">= 2"
  s.add_development_dependency "yard", "~> 0.6.0"
  s.add_development_dependency "ruby-debug19"
  s.add_development_dependency "pry"
  
  s.add_dependency "bundler"
  s.add_dependency "rake"
  s.add_dependency "ffi"
  s.add_dependency "ffi-rzmq"
  s.add_dependency "activesupport"
  s.add_dependency "daemons"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

module ZmqJobs
  class Railties < Rails::Railties
    config.autoload_paths << Rails.root.join('app', 'workers')
  end
end
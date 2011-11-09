$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'zmq_jobs'
message = lambda{|num|"Message ##{num}"}
index = 0

Signal.trap('INT') do
  publisher.stop
end

publisher = ZmqJobs::Socket::Pub.new(
  'host' => '127.0.0.1',
  'port' => 2200
)
publisher.run do |socket|
  msg = message.call(index)
  socket.send_string(msg)
  puts "Send message: #{msg}"
  index += 1
  sleep 2
end.terminate

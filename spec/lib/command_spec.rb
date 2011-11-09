require 'spec_helper.rb'

describe ZmqJobs::Command do
  before do
  end
  
  context do
    subject{ZmqJobs::Command.new(ZmqJobs::Broker, [1]).options}
    
    it 'should have options by default' do
      subject[:config_file].should == ZmqJobs::Broker.default_config_file
      subject[:daemonize].should be_false
      subject[:monitor].should be_false
    end
  end
end
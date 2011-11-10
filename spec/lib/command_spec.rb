require 'spec_helper.rb'

describe ZmqJobs::BrokerCommand do
  let(:command) do
    ZmqJobs::BrokerCommand.any_instance.stub(:read_config_file => options, :start => true)
    ZmqJobs::BrokerCommand.new(args)
  end
  let(:options){{:key1 => :value1, :key2 => :value2}}
  
  context 'without option' do
    let(:args){['start']}
    
    specify{command.daemonize.should be_false}
    specify{command.monitor.should be_false}
    specify{command.config_file.should == './config/zmq_jobs.yml'}
    specify{command.execute_dir.should == Dir.pwd}
    specify{command.options.should == options}
    specify{command.type.should == 'broker'}
    specify{command.daemon_class.should == ZmqJobs::Broker}
  end
  
  context 'with option -d' do
    let(:args){['start', '-d']}
    
    specify{command.daemonize.should be_true}
    specify{command.monitor.should be_false}
    specify{command.config_file.should == './config/zmq_jobs.yml'}
  end
  
  context 'with option -m' do
    let(:args){['start', '-m']}
    
    specify{command.daemonize.should be_false}
    specify{command.monitor.should be_true}
    specify{command.config_file.should == './config/zmq_jobs.yml'}
  end
  
  context 'with option -c' do
    let(:args){['start', '-c', 'bla-bla-bla']}
    
    specify{command.daemonize.should be_false}
    specify{command.monitor.should be_false}
    specify{command.config_file.should == 'bla-bla-bla'}
  end
end

require 'spec_helper.rb'

class TestWorker
end

describe ZmqJobs::Command do
  describe 'new' do
    let(:command) do
      ZmqJobs::Command.new(['start'])
    end
    
    it 'should raise exception' do
      lambda{command}.should raise_error(RuntimeError)
    end
  end
end

shared_examples_for :new_common_options do
  let(:daemon_options){{:key => :value}}
  
  context 'without options' do
    let(:args){['start']}
    
    specify{command.daemonize.should be_false}
    specify{command.monitor.should be_false}
    specify{command.config_file.should == './config/zmq_jobs.yml'}
    specify{command.execute_dir.should == Dir.pwd}
    specify{command.options.should == options}
    specify{command.type.should == type}
    specify{command.daemon_class(daemon).should == classname}
    specify{command.send(:daemon_config, daemon).should == daemon_options}
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

describe ZmqJobs::BrokerCommand do
  describe 'new' do
    let(:command) do
      ZmqJobs::BrokerCommand.any_instance.stub(:read_config_file => options, :start => true)
      ZmqJobs::BrokerCommand.new(args)
    end
    let(:type){'broker'}
    let(:daemon){type}
    let(:classname){ZmqJobs::Broker}
    let(:options){{daemon => daemon_options}}
    
    it_behaves_like :new_common_options
  end
end

describe ZmqJobs::BalancerCommand do
  describe 'new' do
    let(:command) do
      ZmqJobs::BalancerCommand.any_instance.stub(:read_config_file => options, :start => true)
      ZmqJobs::BalancerCommand.new(args)
    end
    let(:type){'balancer'}
    let(:daemon){type}
    let(:classname){ZmqJobs::Balancer}
    let(:options){{daemon => daemon_options}}
    
    it_behaves_like :new_common_options
  end
end

describe ZmqJobs::WorkerCommand do
  describe 'new' do
    let(:command) do
      ZmqJobs::WorkerCommand.any_instance.stub(:read_config_file => options, :start => true)
      ZmqJobs::WorkerCommand.new(args)
    end
    let(:type){'worker'}
    let(:daemon){'test_worker'}
    let(:classname){TestWorker}
    let(:options){{'workers' => {daemon => daemon_options}}}
    
    it_behaves_like :new_common_options
  end
end

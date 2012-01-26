require 'spec_helper.rb'

TestWorker = Class.new(ZmqJobs::Worker::Base) unless defined?(TestWorker)
AnotherTestWorker = Class.new(ZmqJobs::Worker::Base) unless defined?(AnotherTestWorker)

describe ZmqJobs::Command do
  describe '.new' do
    let(:command) do
      ZmqJobs::Command.new(['start'])
    end
    
    it 'should raise exception' do
      lambda{command}.should raise_error(RuntimeError)
    end
  end
end

shared_examples_for 'initialization' do
  let(:daemon_options){{:key => :value}}
  
  context 'without options' do
    let(:args){['start']}
    
    specify{command.daemonize.should be_false}
    specify{command.monitor.should be_false}
    specify{command.config_file.should == './config/zmq_jobs.yml'}
    specify{command.execute_dir.should == Dir.pwd}
    specify{command.options.should == options['test']}
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

shared_examples_for 'environment_options' do
  ['development', 'production', 'beta', 'test'].each do |env|
    context "with #{env} environment" do
      before do
        ENV['ZMQ_ENV'] = env
      end
      
      after do
        ENV['ZMQ_ENV'] = 'test'
      end
      
      let(:args){['start']}
      let(:options) do
        {
          'development' => {:key => 'development'},
          'production' => {:key => 'production'},
          'beta' => {:key => 'beta'},
          'test' => {:key => 'test'}
        }
      end
      
      specify{command.send(:environment_options).should == {:key => env}}
    end
  end
end

shared_examples_for 'daemonization' do
  let(:args){['start']}
  let(:daemon_options){{:key => :value}}
  
  specify{command.start}
end

describe ZmqJobs::BrokerCommand do
  before do
    ENV['ZMQ_ENV'] = 'test'
    ZmqJobs::BrokerCommand.any_instance.stub(:read_config_file => options)
  end
  
  let(:command){ZmqJobs::BrokerCommand.new(args)}
  let(:type){'broker'}
  let(:daemon){type}
  let(:options){{'test' => {daemon => daemon_options}}}
  
  describe '.new' do
    before do
      ZmqJobs::BrokerCommand.any_instance.stub(:start => true)
    end
    
    let(:classname){ZmqJobs::Broker}
    
    it_behaves_like 'initialization'
  end
  
  describe '#environment_options' do
    it_behaves_like 'environment_options'
  end
  
  describe '#start' do
    before do
      ZmqJobs::BrokerCommand.any_instance.should_receive(:start_daemon).with(daemon, daemon_options).and_return(true)
    end
    
    it_behaves_like 'daemonization'
  end
end

describe ZmqJobs::BalancerCommand do
  before do
    ENV['ZMQ_ENV'] = 'test'
    ZmqJobs::BalancerCommand.any_instance.stub(:read_config_file => options)
  end
  
  let(:command){ZmqJobs::BalancerCommand.new(args)}
  let(:type){'balancer'}
  let(:daemon){type}
  let(:options){{'test' => {daemon => daemon_options}}}
  
  describe '.new' do
    before do
      ZmqJobs::BalancerCommand.any_instance.stub(:start => true)
    end
    
    let(:classname){ZmqJobs::Balancer}
    
    it_behaves_like 'initialization'
  end
  
  describe '#environment_options' do
    it_behaves_like 'environment_options'
  end
  
  describe '#start' do
    before do
      ZmqJobs::BalancerCommand.any_instance.should_receive(:start_daemon).with(daemon, daemon_options).and_return(true)
    end
    
    it_behaves_like 'daemonization'
  end
end

describe ZmqJobs::WorkerCommand do
  before do
    ENV['ZMQ_ENV'] = 'test'
    ZmqJobs::WorkerCommand.any_instance.stub(:read_config_file => options)
  end
  
  let(:command){ZmqJobs::WorkerCommand.new(args)}
  let(:type){'worker'}
  
  describe '.new' do
    before do
      ZmqJobs::WorkerCommand.any_instance.stub(:start => true)
    end
    
    let(:daemon){'test_worker'}
    let(:classname){TestWorker}
    let(:options){{'test' => {'workers' => {daemon => daemon_options}}}}
    
    it_behaves_like 'initialization'
    
    context 'test workers initialization' do
      let(:daemon_options){{:key => :value}}
      context do
        let(:workers){%W{worker1 worker2 worker3}}
        let(:args){['start']}

        specify{command.send(:input_workers).should == nil}
        specify{command.send(:all_workers).should == ['test_worker']}      
        specify{command.send(:workers_to_start).should == ['test_worker']}      
      end

      context do
        let(:workers){%W{worker1 worker2 worker3}}
        let(:args){['start', '-w', workers.join(',')]}

        specify{command.send(:input_workers).should == workers}
        specify{command.send(:all_workers).should == ['test_worker']}      
        specify{command.send(:workers_to_start).should == []}      
      end
      
      context do
        let(:workers){%W{worker1 worker2 worker3 test_worker}}
        let(:args){['start', '-w', workers.join(',')]}
      
        specify{command.send(:input_workers).should == workers}
        specify{command.send(:all_workers).should == ['test_worker']}      
        specify{command.send(:workers_to_start).should == ['test_worker']}
      end 
    end
  end
  
  describe '#environment_options' do
    it_behaves_like 'environment_options'
  end
  
  describe '#start' do
    before do
      ZmqJobs::WorkerCommand.any_instance.stub(:workers_to_start => workers)
      ZmqJobs::WorkerCommand.any_instance.stub(:preload_worker_class => true)
    end
    
    let(:args){['start', '-d']}
    let(:first_daemon_options){{:key => :first}}
    
    context 'daemonization for one worker' do
      let(:workers){%W{test_worker}}
      let(:options){{'test' => {'workers' => {workers.first => first_daemon_options}}}}
      
      before do
        command.should_receive(:start_daemon).
          with(workers.first, first_daemon_options).and_return(true)
      end
      
      specify{command.start}
    end
    
    context 'daemonization for many workers' do
      let(:workers){%W{test_worker another_test_worker}}
      let(:last_daemon_options){{:key => :last}}
      let(:options){{'test' => {'workers' => {
        workers.first => first_daemon_options,
        workers.last => last_daemon_options
      }}}}
      
      before do
        command.should_receive(:start_daemon).
          with(workers.first, first_daemon_options).and_return(true)
        command.should_receive(:start_daemon).
          with(workers.last, last_daemon_options).and_return(true)
      end
      
      specify{command.start}
    end
  end
  
  describe '#daemon_classname' do
    let(:args){['start']}
    let(:options){{'test' => {'workers' => {
      'test_worker' => {},
      'test_worker_clone' => {'classname' => 'TestWorker'}
    }}}}
    
    specify{command.send(:daemon_classname, 'test_worker').should == 'TestWorker'}
    specify{command.send(:daemon_classname, 'test_worker_clone').should == 'TestWorker'}
  end
end

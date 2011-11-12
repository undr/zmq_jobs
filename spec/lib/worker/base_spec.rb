require 'spec_helper.rb'

TestWorker = Class.new(ZmqJobs::Worker::Base)
ZmqJobs.logger = Logger.new('/dev/null')
describe ZmqJobs::Worker::Base do
  describe '.cmd' do
    before do
      worker = mock(:worker, :start => true)
      TestWorker.should_receive(:new).with(result_options).and_return(worker)
    end
    
    subject{TestWorker.cmd(options)}
    
    context 'without arguments' do
      let(:options){[]}
      let(:result_options){{}}
      
      specify{subject.should be_true}
    end
    
    context 'with one argument' do
      let(:options){['127.0.0.1']}
      let(:result_options){{'hosts' => '127.0.0.1'}}
      
      specify{subject.should be_true}
    end
    
    context 'with two arguments' do
      let(:options){['127.0.0.1', '2200']}
      let(:result_options){{'hosts' => '127.0.0.1', 'ports' => [2200]}}
      
      specify{subject.should be_true}
    end
    
    context 'with three arguments' do
      let(:options){['127.0.0.1', '2200', '3']}
      let(:result_options){{'hosts' => '127.0.0.1', 'ports' => [2200, 2201, 2202, 2203]}}
      
      specify{subject.should be_true}
    end
    
    context 'with four arguments' do
      let(:options){['127.0.0.1', '2200', '3', '2']}
      let(:result_options){{'hosts' => '127.0.0.1', 'ports' => [2200, 2201, 2202, 2203], 'iothreads' => 2}}
      
      specify{subject.should be_true}
    end
  end
  
  describe '.start' do
    before do
      subscriber = mock(:subscriber)
      subscriber.should_receive(:run).and_yield(worker).and_return(true)
      worker.stub(:subscriber => subscriber)
      worker.stub(:recv => 'Message')
      worker.should_receive(:execute).with('Message').and_return(true)
      ZMQ::Util.stub(:resultcode_ok? => true)
    end
    
    let(:worker){TestWorker.new}
    
    specify{worker.start.should be_true}
  end
end

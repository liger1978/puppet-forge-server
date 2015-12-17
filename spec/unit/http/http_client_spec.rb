require 'spec_helper'
require 'puppet_forge_server'

describe PuppetForgeServer::Http::HttpClient do
  let(:port) do
    require 'socket'
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    server.close
    port
  end
  let(:uri) { "http://localhost:#{port}/" }
  before(:each) do
    @server = TCPServer.new('localhost', port)
    @thr = Thread.new do
      loop do
        socket = @server.accept
        response = "Hello!"
        socket.print "HTTP/1.1 200 OK\r\n" +
                     "Content-Type: text/plain\r\n" +
                     "Content-Length: #{response.bytesize}\r\n" +
                     "Connection: close\r\n"
        socket.print "\r\n"
        sleep 0.01
        socket.print response
        socket.close
      end
    end
  end
  after(:each) do
    @server.close
    @thr.kill
  end
  let(:instance) { described_class.new(cache) }
  describe '#download' do
    subject do
      99.times { instance.download(uri) }
      instance.download(uri)
    end
    context 'with 1sec LRU cache' do
      let(:cache) do
        require 'lrucache'
        LRUCache.new(:ttl => 1)
      end
      it { expect(subject).not_to be_nil }
      it { expect(subject).not_to be_closed }
    end
    context 'with default cache' do
      let(:cache) { nil }
      it { expect(subject).not_to be_nil }
      it { expect(subject).not_to be_closed }
    end
  end
  describe '#get' do
    subject do
      99.times { instance.get(uri) }
      instance.get(uri)
    end
    context 'with 1sec LRU cache' do
      let(:cache) do
        require 'lrucache'
        LRUCache.new(:ttl => 1)
      end
      it { expect(subject).to eq('Hello!') }
    end
    context 'with default cache' do
      let(:cache) { nil }
      it { expect(subject).to eq('Hello!') }
    end
  end
end

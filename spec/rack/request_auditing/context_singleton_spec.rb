require 'spec_helper'

describe Rack::RequestAuditing::ContextSingleton do
  after(:all) do
    Thread.current[Rack::RequestAuditing::ContextSingleton::SERVER_CONTEXT_KEY] = nil
    Thread.current[Rack::RequestAuditing::ContextSingleton::CLIENT_CONTEXT_KEY] = nil
  end

  describe '.context' do
    context 'when client context is available' do
      it 'returns the client context' do
        client_context = double('client context')
        Thread.current[Rack::RequestAuditing::ContextSingleton::CLIENT_CONTEXT_KEY] = client_context
        expect(described_class.context).to eq client_context
      end
    end

    context 'when the client context is not available' do
      it 'returns the service context' do
        server_context = double('service context')
        Thread.current[Rack::RequestAuditing::ContextSingleton::SERVER_CONTEXT_KEY] = server_context
        Thread.current[Rack::RequestAuditing::ContextSingleton::CLIENT_CONTEXT_KEY] = nil
        expect(described_class.context).to eq server_context
      end
    end
  end

  describe '.server_context' do
    context 'when the service context is not set' do
      it 'sets the service context to a new context' do
        Thread.current[Rack::RequestAuditing::ContextSingleton::SERVER_CONTEXT_KEY] = nil
        context = double('service context')
        allow(Rack::RequestAuditing::Context).to receive(:new)
          .and_return(context)
        expect(Thread.current).to receive(:[]=)
          .with(Rack::RequestAuditing::ContextSingleton::SERVER_CONTEXT_KEY, context)
        described_class.server_context
      end

      it 'returns the service context' do
        context = double('service context')
        Thread.current[Rack::RequestAuditing::ContextSingleton::SERVER_CONTEXT_KEY] = context
        expect(described_class.server_context).to eq context
      end
    end
  end

  describe ".client_context" do
    it 'returns the client context' do
      context = double('client context')
      Thread.current[Rack::RequestAuditing::ContextSingleton::CLIENT_CONTEXT_KEY] = context
      expect(described_class.client_context).to eq context
    end
  end

  describe '.set_client_context' do
    it 'sets the client context to a new context' do
      context = double('client context')
      allow(Rack::RequestAuditing::Context).to receive(:new).and_return(context)
      expect(Thread.current).to receive(:[]=)
        .with(Rack::RequestAuditing::ContextSingleton::CLIENT_CONTEXT_KEY, context)
      described_class.set_client_context
    end
  end

  describe '.unset_client_context' do
    it 'sets the client context to nothing' do
      context = double('client context')
      expect(Thread.current).to receive(:[]=)
        .with(Rack::RequestAuditing::ContextSingleton::CLIENT_CONTEXT_KEY, nil)
      described_class.unset_client_context
    end
  end
end

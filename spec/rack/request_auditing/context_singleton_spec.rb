require 'spec_helper'

describe Rack::RequestAuditing::ContextSingleton do
  after(:all) do
    Thread.current[Rack::RequestAuditing::ContextSingleton::CONTEXT_KEY] = nil
  end

  describe '.context' do
    context 'when the context is not set' do
      before do
        Thread.current[Rack::RequestAuditing::ContextSingleton::CONTEXT_KEY] = nil
      end

      it 'sets the context to a new context' do
        context = double('context')
        allow(Rack::RequestAuditing::Context).to receive(:new)
          .and_return(context)
        expect(Thread.current).to receive(:[]=)
          .with(Rack::RequestAuditing::ContextSingleton::CONTEXT_KEY, context)
        described_class.context
      end

      it 'returns the new context' do
        context = double('context')
        allow(Rack::RequestAuditing::Context).to receive(:new)
          .and_return(context)
        expect(described_class.context).to eq context
      end
    end

    context 'when the context is set' do
      it 'returns the context' do
        context = double('context')
        Thread.current[Rack::RequestAuditing::ContextSingleton::CONTEXT_KEY] = context
        expect(described_class.context).to eq context
      end
    end
  end

  describe '.set_attribute' do
    let(:context) { double('context') }

    before do
      Thread.current[Rack::RequestAuditing::ContextSingleton::CONTEXT_KEY] = context
    end

    context 'when attribute is correlation_id' do
      it 'sets the context correlation id to the provided value' do
        id = double('correlation id')
        expect(context).to receive(:correlation_id=).with(id)
        described_class.set_attribute('correlation_id', id)
      end
    end

    context 'when attribute is request_id' do
      it 'sets the context request id to the provided value' do
        id = double('request id')
        expect(context).to receive(:request_id=).with(id)
        described_class.set_attribute('request_id', id)
      end
    end

    context 'when attribute is parent_request_id' do
      it 'sets the context parent request id to the provided value' do
        id = double('parent request id')
        expect(context).to receive(:parent_request_id=).with(id)
        described_class.set_attribute('parent_request_id', id)
      end
    end

    context 'when attribute is not correlation_id, request_id, or parent_request_id' do
      it 'does not set the attribute on the context' do
        id = double('foo id')
        expect(context).not_to receive(:foo_id=)
        described_class.set_attribute('foo_id', id)
      end
    end
  end
end

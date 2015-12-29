require 'spec_helper'

describe Rack::RequestAuditing::Context do
  subject { Rack::RequestAuditing::Context.new }

  describe '#create_child_context' do
    let(:correlation_id) { double('correlation id') }
    let(:request_id) { double('request id') }
    let(:parent_request_id) { double('parent request id') }

    before do
      subject.correlation_id = correlation_id
      subject.request_id = request_id
      subject.parent_request_id = parent_request_id
    end

    it 'creates a new instance' do
      child = double('child context').as_null_object
      expect(described_class).to receive(:new).and_return(child)
      subject.create_child_context
    end

    it 'sets the correlation id on the child context' do
      child = double('child context').as_null_object
      allow(described_class).to receive(:new).and_return(child)
      expect(child).to receive(:correlation_id=).with(correlation_id)
      subject.create_child_context
    end

    it 'sets the parent request id on the child context' do
      child = double('child context').as_null_object
      allow(described_class).to receive(:new).and_return(child)
      expect(child).to receive(:parent_request_id=).with(request_id)
      subject.create_child_context
    end

    it 'sets a new request id on the child context' do
      child = double('child context').as_null_object
      allow(described_class).to receive(:new).and_return(child)
      request_id = double('request id')
      allow(Rack::RequestAuditing::IdGenerator).to receive(:generate)
        .and_return(request_id)
      expect(child).to receive(:request_id=).with(request_id)
      subject.create_child_context
    end
  end
end

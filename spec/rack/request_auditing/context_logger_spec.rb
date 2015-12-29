require 'spec_helper'

describe Rack::RequestAuditing::ContextLogger do
  subject { Rack::RequestAuditing::ContextLogger.new('/dev/null') }

  describe '#initialize' do
    it 'creates a new log formatter' do
      expect(Rack::RequestAuditing::LogFormatter).to receive(:new)
      subject
    end

    it 'sets the formatter to a new log formatter' do
      formatter = double('formatter')
      allow(Rack::RequestAuditing::LogFormatter).to receive(:new)
        .and_return(formatter)
      expect(subject.formatter).to eq formatter
    end
  end

  describe '#format_message' do
    let(:severity) { double('severity') }
    let(:time) { Time.now }
    let(:progname) { double('progname') }
    let(:original_msg) { double('original message') }

    it 'annotates the message with context tags' do
      expect(subject).to receive(:annotate_message_with_context)
        .with(original_msg)
      progname = double('progname')
      subject.format_message(severity, time, progname, original_msg)
    end

    it 'formats message with new arguments' do
      annotated_msg = double('annotated message')
      allow(subject).to receive(:annotate_message_with_context)
        .with(original_msg).and_return(annotated_msg)
      expect(subject.formatter).to receive(:call)
        .with(severity, time, progname, annotated_msg)
      subject.format_message(severity, time, progname, original_msg)
    end
  end

  describe '#annotate_message_with_context' do
    it 'annotates message with context tags' do
      msg = double('message')
      context_tags = double('context tags hash')
      allow(subject).to receive(:context_tags).and_return(context_tags)
      expect(Rack::RequestAuditing::MessageAnnotator).to receive(:annotate)
        .with(msg, context_tags)
      subject.annotate_message_with_context(msg)
    end

    it 'returns the annotated message' do
      msg = double('message')
      context_tags = double('context tags hash')
      allow(subject).to receive(:context_tags).and_return(context_tags)
      annotated_msg = double('annotated message')
      allow(Rack::RequestAuditing::MessageAnnotator).to receive(:annotate)
        .with(msg, context_tags).and_return(annotated_msg)
      expect(subject.annotate_message_with_context(msg)).to eq annotated_msg
    end
  end

  describe '#context_tags' do
    let(:context) { double('context').as_null_object }

    before do
      subject.context = context
    end

    it 'gets correlation id from current context' do
      expect(context).to receive(:correlation_id)
      subject.context_tags
    end

    it 'gets request id from current context' do
      expect(context).to receive(:request_id)
      subject.context_tags
    end

    it 'gets parent request id from current context' do
      expect(context).to receive(:parent_request_id)
      subject.context_tags
    end

    it 'returns a hash of the current context attributes' do
      correlation_id = double('correlation id')
      request_id = double('request id')
      parent_request_id = double('parent request id')
      allow(context).to receive(:correlation_id).and_return(correlation_id)
      allow(context).to receive(:request_id).and_return(request_id)
      allow(context).to receive(:parent_request_id)
        .and_return(parent_request_id)
      expect(subject.context_tags).to eq(
        {
          correlation_id: correlation_id,
          request_id: request_id,
          parent_request_id: parent_request_id
        }
      )
    end
  end
end

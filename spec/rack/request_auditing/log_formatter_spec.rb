require 'spec_helper'

describe Rack::RequestAuditing::LogFormatter do
  subject { Rack::RequestAuditing::LogFormatter.new }

  describe '#initialize' do
    it 'sets the datetime format to the default' do
      expect(subject.datetime_format)
        .to eq Rack::RequestAuditing::LogFormatter::DATETIME_FORMAT
    end
  end

  describe '#call' do
    let(:severity) { 'SEVERITY' }
    let(:datetime) { Time.now }
    let(:progname) { 'PROGNAME' }
    let(:msg) { double('message') }

    it 'dumps the message appropriately' do
      expect(subject).to receive(:msg2str).with(msg)
      subject.call(severity, datetime, progname, msg)
    end

    it 'annotates the message with context tags' do
      allow(subject).to receive(:msg2str).with(msg).and_return('FOOBAR')
      context_tags = double('context tags')
      allow(subject).to receive(:context_tags).and_return(context_tags)
      expect(Rack::RequestAuditing::MessageAnnotator).to receive(:annotate)
        .with('FOOBAR', context_tags)
      subject.call(severity, datetime, progname, msg)
    end

    it 'formats the datetime with the datetime format' do
      datetime_format = double('datetime format string')
      subject.instance_variable_set(:@datetime_format, datetime_format)
      expect(datetime).to receive(:strftime).with(datetime_format)
      subject.call(severity, datetime, progname, msg)
    end

    it 'returns the interpolated log message' do
      allow(subject).to receive(:msg2str).with(msg).and_return('FOOBAR')
      context_tags = double('context tags')
      allow(subject).to receive(:context_tags).and_return(context_tags)
      allow(Rack::RequestAuditing::MessageAnnotator).to receive(:annotate)
        .with('FOOBAR', context_tags).and_return('FOOBAR {tag="value"}')
      allow(datetime).to receive(:strftime).and_return('FORMATTEDTIME')
      expect(subject.call(severity, datetime, progname, msg))
        .to eq "FORMATTEDTIME [PROGNAME] SEVERITY FOOBAR {tag=\"value\"}\n"
    end
  end

  describe '#context_tags' do
    it 'returns a hash of the current context attributes' do
      correlation_id = double('correlation id')
      request_id = double('request id')
      parent_request_id = double('parent request id')
      allow(Rack::RequestAuditing::ContextSingleton).to receive(:correlation_id)
        .and_return(correlation_id)
      allow(Rack::RequestAuditing::ContextSingleton).to receive(:request_id)
        .and_return(request_id)
      allow(Rack::RequestAuditing::ContextSingleton).to receive(:parent_request_id)
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

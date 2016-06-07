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
      allow(datetime).to receive(:strftime).and_return('FORMATTEDTIME')
      expect(subject.call(severity, datetime, progname, msg))
        .to eq "app=\"PROGNAME\" severity=\"SEVERITY\" time=\"FORMATTEDTIME\" FOOBAR\n"
    end
  end
end

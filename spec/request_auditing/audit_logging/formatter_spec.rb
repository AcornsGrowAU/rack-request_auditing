require 'spec_helper'

describe RequestAuditing::AuditLogging::Formatter do
  subject { RequestAuditing::AuditLogging::Formatter.new }

  describe '#initialize' do
    it 'sets the datetime format to the default' do
      expect(subject.datetime_format)
        .to eq RequestAuditing::AuditLogging::Formatter::DATETIME_FORMAT
    end
  end

  describe '#call' do
    let(:severity) { 'SEVERITY' }
    let(:datetime) { Time.now }
    let(:progname) { 'PROGNAME' }
    let(:msg) { double('message') }

    before do
      allow(subject).to receive(:dump_env_variable)
        .with(RequestAuditing::AuditLogging::Formatter::CORRELATION_ID_KEY)
      allow(subject).to receive(:dump_env_variable)
        .with(RequestAuditing::AuditLogging::Formatter::REQUEST_ID_KEY)
      allow(subject).to receive(:dump_env_variable)
        .with(RequestAuditing::AuditLogging::Formatter::PARENT_ID_KEY)
    end

    it 'dumps the message appropriately' do
      expect(subject).to receive(:msg2str).with(msg)
      subject.call(severity, datetime, progname, msg)
    end

    it 'dumps the correlation id header' do
      expect(subject).to receive(:dump_env_variable)
        .with(RequestAuditing::AuditLogging::Formatter::CORRELATION_ID_KEY)
      subject.call(severity, datetime, progname, msg)
    end

    it 'dumps the request id header' do
      expect(subject).to receive(:dump_env_variable)
        .with(RequestAuditing::AuditLogging::Formatter::REQUEST_ID_KEY)
      subject.call(severity, datetime, progname, msg)
    end

    it 'dumps the parent id header' do
      expect(subject).to receive(:dump_env_variable)
        .with(RequestAuditing::AuditLogging::Formatter::PARENT_ID_KEY)
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
      allow(subject).to receive(:dump_env_variable)
        .with(RequestAuditing::AuditLogging::Formatter::CORRELATION_ID_KEY)
        .and_return('CORRELATION_ID')
      allow(subject).to receive(:dump_env_variable)
        .with(RequestAuditing::AuditLogging::Formatter::REQUEST_ID_KEY)
        .and_return('REQUEST_ID')
      allow(subject).to receive(:dump_env_variable)
        .with(RequestAuditing::AuditLogging::Formatter::PARENT_ID_KEY)
        .and_return('PARENT_ID')
      allow(datetime).to receive(:strftime).and_return('FORMATTEDTIME')
      expect(subject.call(severity, datetime, progname, msg))
        .to eq "FORMATTEDTIME [PROGNAME] SEVERITY FOOBAR - correlation_id=CORRELATION_ID, request_id=REQUEST_ID, parent_id=PARENT_ID\n"
    end
  end

  describe '#dump_env_variable' do
    context 'when env is set' do
      let(:env) { double('env') }

      before do
        subject.env = env
      end

      context 'when env variable is set' do
        it 'returns the value wrapped by quotes' do
          allow(env).to receive(:has_key?).with('foo').and_return(true)
          allow(env).to receive(:[]).with('foo').and_return('bar')
          expect(subject.dump_env_variable('foo')).to eq '"bar"'
        end
      end

      context 'when env variable is not set' do
        it 'returns null as a string' do
          allow(env).to receive(:has_key?).with('foo').and_return(false)
          expect(subject.dump_env_variable('foo')).to eq 'null'
        end
      end
    end

    context 'when env is not set' do
      it 'returns null as a string' do
        expect(subject.dump_env_variable('foo')).to eq 'null'
      end
    end
  end
end

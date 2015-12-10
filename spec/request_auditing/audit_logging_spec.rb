require 'spec_helper'

describe RequestAuditing::AuditLogging do
  let(:logger_klass) do
    Class.new do
      def initialize(logdev, shift_age, shift_size); end
    end
  end
  let(:audit_logging_klass) do
    Class.new(logger_klass) do
      include RequestAuditing::AuditLogging
    end
  end

  subject { audit_logging_klass.new(STDOUT) }

  describe '#initialize' do
    it 'calls superclass initializer' do
      expect_any_instance_of(logger_klass).to receive(:initialize)
      audit_logging_klass.new(STDOUT)
    end

    it 'sets @formatter to a new formatter' do
      formatter = double('formatter')
      allow(RequestAuditing::AuditLogging::Formatter).to receive(:new)
        .and_return(formatter)
      expect(subject.instance_variable_get(:@formatter)).to eq formatter
    end
  end

  describe '#set_formatter_env' do
    let(:env) { double('env') }
    let(:formatter) { double('formatter').as_null_object }

    it 'sets the formatter env' do
      subject.instance_variable_set(:@formatter, formatter)
      expect(formatter).to receive(:env=).with(env)
      subject.set_formatter_env(env)
    end
  end

  describe ".extended" do
    it 'sets a new formatter on the instance' do
      formatter = double('formatter')
      allow(RequestAuditing::AuditLogging::Formatter).to receive(:new)
        .and_return(formatter)
      logger = double('logger')
      expect(logger).to receive(:formatter=).with(formatter)
      logger.extend(RequestAuditing::AuditLogging)
    end
  end
end

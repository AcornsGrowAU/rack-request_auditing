require 'spec_helper'

describe Rack::RequestAuditing do
  it 'has a version number' do
    expect(Rack::RequestAuditing::VERSION).not_to be nil
  end

  describe '.new' do
    let(:app) { double('app') }

    context 'when logger option is set' do
      it 'sets logger singleton to the provided logger' do
        logger = double('external logger')
        Rack::RequestAuditing.new(app, logger: logger)
        expect(Rack::RequestAuditing.instance_variable_get(:@logger))
          .to eq logger
      end
    end

    context 'when logger option is not set' do
      it 'sets the logger singleton to a new formatted logger' do
        logger = double('formatted logger')
        allow(Rack::RequestAuditing).to receive(:formatted_logger)
          .and_return(logger)
        Rack::RequestAuditing.new(app, foo: 'bar')
        expect(Rack::RequestAuditing.instance_variable_get(:@logger))
          .to eq logger
      end
    end

    it 'creates a new auditor instance' do
      expect(Rack::RequestAuditing::Auditor).to receive(:new).with(app)
      Rack::RequestAuditing.new(app)
    end

    it 'returns the auditor instance' do
      auditor = double('auditor')
      allow(Rack::RequestAuditing::Auditor).to receive(:new).with(app)
        .and_return(auditor)
      expect(Rack::RequestAuditing.new(app)).to eq auditor
    end
  end

  describe '.logger' do
    it 'returns the logger singleton' do
      logger = double('logger')
      Rack::RequestAuditing.instance_variable_set(:@logger, logger)
      expect(Rack::RequestAuditing.logger).to eq logger
    end
  end

  describe '.formatted_logger' do
    it 'creates a new logger to STDOUT' do
      logger = double('logger').as_null_object
      expect(::Logger).to receive(:new).with(STDOUT).and_return(logger)
      Rack::RequestAuditing.formatted_logger
    end

    it 'sets the formatter on the new logger' do
      logger = double('logger').as_null_object
      allow(::Logger).to receive(:new).with(STDOUT).and_return(logger)
      formatter = double('formatter')
      allow(Rack::RequestAuditing::LogFormatter).to receive(:new)
        .and_return(formatter)
      expect(logger).to receive(:formatter=).with(formatter)
      Rack::RequestAuditing.formatted_logger
    end

    it 'returns the formatted logger' do
      logger = double('logger').as_null_object
      allow(::Logger).to receive(:new).with(STDOUT).and_return(logger)
      expect(Rack::RequestAuditing.formatted_logger).to eq logger
    end
  end

  describe '.log_typed_event' do
    let(:msg) { double('message') }
    let(:type) { double('type') }
    let(:logger) { double('logger') }

    before do
      allow(Rack::RequestAuditing).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)
    end

    it 'annotates the message with the type' do
      expect(Rack::RequestAuditing::MessageAnnotator).to receive(:annotate)
        .with(msg, type: type)
      Rack::RequestAuditing.log_typed_event(msg, type)
    end

    it 'logs the annotated message' do
      annotated_message = double('annotated message')
      allow(Rack::RequestAuditing::MessageAnnotator).to receive(:annotate)
        .with(msg, type: type).and_return(annotated_message)
      expect(logger).to receive(:info).with(annotated_message)
      Rack::RequestAuditing.log_typed_event(msg, type)
    end
  end
end

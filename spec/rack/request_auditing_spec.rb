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
    it 'creates a new context logger to STDOUT' do
      logger = double('logger').as_null_object
      expect(Rack::RequestAuditing::ContextLogger).to receive(:new).with(STDOUT)
        .and_return(logger)
      Rack::RequestAuditing.formatted_logger
    end

    it 'sets the context on the new logger to the context singleton' do
      logger = double('logger').as_null_object
      allow(Rack::RequestAuditing::ContextLogger).to receive(:new).with(STDOUT)
        .and_return(logger)
      expect(logger).to receive(:context=)
        .with(Rack::RequestAuditing::ContextSingleton)
      Rack::RequestAuditing.formatted_logger
    end

    it 'returns the formatted logger' do
      logger = double('logger').as_null_object
      allow(Rack::RequestAuditing::ContextLogger).to receive(:new).with(STDOUT)
        .and_return(logger)
      expect(Rack::RequestAuditing.formatted_logger).to eq logger
    end
  end
end

require 'spec_helper'

describe Rack::RequestAuditing::Auditor do
  let(:app) { double('app') }
  subject { Rack::RequestAuditing::Auditor.new(app) }

  describe '#initialize' do
    it 'initializes the app' do
      expect(subject.instance_variable_get(:@app)).to eq app
    end

    context 'when options are provided' do
      context 'when logger option is set' do
        it 'sets @logger to external logger' do
          logger = double('external logger')
          auditor = Rack::RequestAuditing::Auditor.new(app, logger: logger)
          expect(auditor.instance_variable_get(:@logger)).to eq logger
        end
      end

      context 'when logger option is not set' do
        it 'sets @logger to new stdout logger instance' do
        logger = double('stdout logger')
        allow(::RequestAuditing::Logger).to receive(:new).with(STDOUT)
          .and_return(logger)
        auditor = Rack::RequestAuditing::Auditor.new(app)
        expect(auditor.instance_variable_get(:@logger)).to eq logger
        end
      end
    end

    context 'when options are not provided' do
      it 'sets @logger to a new STDOUT RequestAuditing::Logger instance' do
        logger = double('stdout logger')
        allow(::RequestAuditing::Logger).to receive(:new).with(STDOUT)
          .and_return(logger)
        auditor = Rack::RequestAuditing::Auditor.new(app)
        expect(auditor.instance_variable_get(:@logger)).to eq logger
      end
    end
  end

  describe '#call' do
    let(:env) { double('env').as_null_object }
    let(:dup_middleware) { double('duplicate middleware').as_null_object }

    it 'duplicates itself' do
      expect(subject).to receive(:dup).and_return(dup_middleware)
      subject.call(env)
    end

    it 'calls _call on the duplicated instance' do
      allow(subject).to receive(:dup).and_return(dup_middleware)
      expect(dup_middleware).to receive(:_call).with(env)
      subject.call(env)
    end
  end

  describe '#_call' do
    let(:env) { double('env') }
    let(:logger) { double('logger').as_null_object }

    before do
      allow(env).to receive(:[]).with(Rack::RequestAuditing::LOGGER_KEY)
        .and_return(logger)
    end

    it 'sets audit logger' do
      expect(subject).to receive(:set_audit_logger).with(env)
      allow(subject).to receive(:ensure_valid_ids).with(env)
      allow(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'ensures valid ids' do
      allow(subject).to receive(:set_audit_logger).with(env)
      expect(subject).to receive(:ensure_valid_ids).with(env)
      allow(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'logs the server receiving a request' do
      allow(subject).to receive(:set_audit_logger).with(env)
      allow(subject).to receive(:ensure_valid_ids).with(env)
      expect(logger).to receive(:info).with('sr')
      allow(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'builds rack response' do
      allow(subject).to receive(:set_audit_logger).with(env)
      allow(subject).to receive(:ensure_valid_ids).with(env)
      expect(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'logs the server sending a response' do
      allow(subject).to receive(:set_audit_logger).with(env)
      allow(subject).to receive(:ensure_valid_ids).with(env)
      expect(logger).to receive(:info).with('ss')
      allow(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'returns the built response' do
      allow(subject).to receive(:set_audit_logger).with(env)
      allow(subject).to receive(:ensure_valid_ids).with(env)
      response = double('response')
      allow(subject).to receive(:build_response).with(env).and_return(response)
      expect(subject._call(env)).to eq response
    end
  end

  describe '#set_audit_logger' do
    let(:env) { double('env').as_null_object }
    let(:logger) { double('logger') }

    before do
      subject.instance_variable_set(:@logger, logger)
    end

    it 'duplicates the configured logger' do
      dup_logger = double('logger dup').as_null_object
      expect(logger).to receive(:dup).and_return(dup_logger)
      allow(dup_logger).to receive(:set_formatter_env)
      subject.send(:set_audit_logger, env)
    end

    context 'when the audit logger is a RequestAuditing::Logger' do
      it 'does not extend the instance with the audit logging module' do
        dup_logger = double('logger dup').as_null_object
        allow(logger).to receive(:dup).and_return(dup_logger)
        allow(dup_logger).to receive(:is_a?).with(::RequestAuditing::Logger)
          .and_return(true)
        expect(dup_logger).not_to receive(:extend)
          .with(::RequestAuditing::AuditLogging)
        subject.send(:set_audit_logger, env)
      end
    end

    context 'when the audit logger is not a RequestAuditing::Logger' do
      it 'extends the instance with the audit logging module' do
        dup_logger = double('logger dup').as_null_object
        allow(logger).to receive(:dup).and_return(dup_logger)
        allow(dup_logger).to receive(:is_a?).with(::RequestAuditing::Logger)
          .and_return(false)
        expect(dup_logger).to receive(:extend)
          .with(::RequestAuditing::AuditLogging)
        subject.send(:set_audit_logger, env)
      end
    end

    it 'sets the env on the audit logger' do
      dup_logger = double('logger dup').as_null_object
      allow(logger).to receive(:dup).and_return(dup_logger)
      allow(dup_logger).to receive(:is_a?).with(::RequestAuditing::Logger)
        .and_return(true)
      expect(dup_logger).to receive(:set_formatter_env).with(env)
      subject.send(:set_audit_logger, env)
    end

    it 'sets the env rack logger to the audit logger' do
      dup_logger = double('logger dup').as_null_object
      allow(logger).to receive(:dup).and_return(dup_logger)
      allow(dup_logger).to receive(:is_a?).with(::RequestAuditing::Logger)
        .and_return(true)
      expect(env).to receive(:[]=)
        .with(Rack::RequestAuditing::LOGGER_KEY, dup_logger)
      subject.send(:set_audit_logger, env)
    end
  end

  describe '#ensure_valid_ids' do
    let(:env) { double('env') }

    it 'ensures a valid correlation id was sent or sets a generated one' do
      expect(Rack::RequestAuditing::HeaderProcessor)
        .to receive(:ensure_valid_id)
        .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      allow(Rack::RequestAuditing::HeaderProcessor)
        .to receive(:ensure_valid_id)
        .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
      subject.send(:ensure_valid_ids, env)
    end

    it 'ensures a valid request id was sent or sets a generated one' do
      allow(Rack::RequestAuditing::HeaderProcessor)
        .to receive(:ensure_valid_id)
        .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      expect(Rack::RequestAuditing::HeaderProcessor)
        .to receive(:ensure_valid_id)
        .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
      subject.send(:ensure_valid_ids, env)
    end
  end

  describe '#build_response' do
    let(:env) { double('env') }

    context 'when neither the correlation or request id is missing' do
      let(:correlation_id) { double('correlation id') }
      let(:request_id) { double('request id') }
      let(:response_headers) { double('response headers').as_null_object }
      let(:middleware_response) { [ double, response_headers, double ] }

      before do
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
          .and_return(correlation_id)
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
          .and_return(request_id)
      end

      it 'passes the incoming request along to the rack app' do
        expect(app).to receive(:call).with(env).and_return(middleware_response)
        subject.send(:build_response, env)
      end

      it 'sets the correlation id header in the response headers' do
        allow(app).to receive(:call).with(env).and_return(middleware_response)
        expect(response_headers).to receive(:[]=)
          .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_HEADER, correlation_id)
        subject.send(:build_response, env)
      end

      it 'sets the request id header in the response headers' do
        allow(app).to receive(:call).with(env).and_return(middleware_response)
        expect(response_headers).to receive(:[]=)
          .with(Rack::RequestAuditing::Auditor::REQUEST_ID_HEADER, request_id)
        subject.send(:build_response, env)
      end

      it 'returns the formatted rack response' do
        allow(app).to receive(:call).with(env).and_return(middleware_response)
        expect(subject.send(:build_response, env)).to eq middleware_response
      end
    end

    context 'when the correlation or request id is missing' do
      before do
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      end

      it 'creates the error response' do
        expect(subject).to receive(:error_response).with(env)
        subject.send(:build_response, env)
      end

      context 'when the correlation id is available' do
        it 'sets the correlation id header in the response headers' do
          id = double('correlation id')
          allow(env).to receive(:[])
            .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
            .and_return(id)
          response_headers = double('response headers').as_null_object
          response = [ double, response_headers, double ]
          allow(subject).to receive(:error_response).with(env)
            .and_return(response)
          expect(response_headers).to receive(:[]=)
            .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_HEADER, id)
          subject.send(:build_response, env)
        end
      end

      context 'when the request id is available' do
        it 'sets the request id header in the response headers' do
          id = double('request id')
          allow(env).to receive(:[])
            .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY).and_return(id)
          response_headers = double('response headers').as_null_object
          response = [ double, response_headers, double ]
          allow(subject).to receive(:error_response).with(env)
            .and_return(response)
          expect(response_headers).to receive(:[]=)
            .with(Rack::RequestAuditing::Auditor::REQUEST_ID_HEADER, id)
          subject.send(:build_response, env)
        end
      end

      it 'returns the formatted rack response' do
        response = [ double, double, double ]
        allow(subject).to receive(:error_response).with(env)
          .and_return(response)
        expect(subject.send(:build_response, env)).to eq response
      end
    end
  end

  describe '#error_response' do
    let(:env) { double('env') }

    it 'returns the error response with environment-dependent error body' do
      error_body = double('error body')
      allow(subject).to receive(:error_body).with(env).and_return(error_body)
      expect(subject.send(:error_response, env)).to eq([422, {}, error_body])
    end
  end

  describe '#error_body' do
    let(:env) { double('env') }

    context 'when only correlation id is missing' do
      it 'returns correlation id error message' do
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
          .and_return(double)
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
          .and_return(nil)
        expect(subject.send(:error_body, env)).to eq ['Invalid Correlation Id']
      end
    end

    context 'when only request id is missing' do
      it 'returns correlation id error message' do
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
          .and_return(nil)
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
          .and_return(double)
        expect(subject.send(:error_body, env)).to eq ['Invalid Request Id']
      end
    end

    context 'when both correlation and request id are missing' do
      it 'returns correlation and request id error message' do
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
          .and_return(nil)
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
          .and_return(nil)
        expect(subject.send(:error_body, env))
          .to eq ['Invalid Correlation Id and Invalid Request Id']
      end
    end

    context 'when neither correlation or request id are missing' do
      it 'returns blank string' do
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
          .and_return(double)
        allow(env).to receive(:[])
          .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
          .and_return(double)
        expect(subject.send(:error_body, env)).to eq ['']
      end
    end
  end
end

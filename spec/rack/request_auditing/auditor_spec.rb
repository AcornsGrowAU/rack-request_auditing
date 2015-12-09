require 'spec_helper'

describe Rack::RequestAuditing::Auditor do
  let(:app) { double('app') }
  subject { Rack::RequestAuditing::Auditor.new(app) }

  describe '#initialize' do
    it 'initializes the app' do
      expect(subject.instance_variable_get(:@app)).to eq app
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

    before do
      allow(env).to receive(:[])
        .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      allow(env).to receive(:[])
        .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
      allow(Rack::RequestAuditing::HeaderProcessor).to receive(:ensure_valid_id)
        .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      allow(Rack::RequestAuditing::HeaderProcessor).to receive(:ensure_valid_id)
        .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
    end

    it 'ensures a valid correlation id was sent or sets a generated one' do
      expect(Rack::RequestAuditing::HeaderProcessor)
        .to receive(:ensure_valid_id)
        .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      subject._call(env)
    end

    it 'ensures a valid request id was sent or sets a generated one' do
      expect(Rack::RequestAuditing::HeaderProcessor)
        .to receive(:ensure_valid_id)
        .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
      subject._call(env)
    end

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
        subject._call(env)
      end

      it 'sets the correlation id header in the response headers' do
        allow(app).to receive(:call).with(env).and_return(middleware_response)
        expect(response_headers).to receive(:[]=)
          .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_HEADER, correlation_id)
        subject._call(env)
      end

      it 'sets the request id header in the response headers' do
        allow(app).to receive(:call).with(env).and_return(middleware_response)
        expect(response_headers).to receive(:[]=)
          .with(Rack::RequestAuditing::Auditor::REQUEST_ID_HEADER, request_id)
        subject._call(env)
      end

      it 'returns the formatted rack response' do
        allow(app).to receive(:call).with(env).and_return(middleware_response)
        expect(subject._call(env)).to eq middleware_response
      end
    end

    context 'when the correlation or request id is missing' do
      it 'creates the error response' do
        expect(subject).to receive(:error_response).with(env)
        subject._call(env)
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
          subject._call(env)
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
          subject._call(env)
        end
      end

      it 'returns the formatted rack response' do
        response = [ double, double, double ]
        allow(subject).to receive(:error_response).with(env)
          .and_return(response)
        expect(subject._call(env)).to eq response
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

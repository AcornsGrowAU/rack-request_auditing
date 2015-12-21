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
      allow(Rack::RequestAuditing).to receive(:log_typed_event)
    end

    it 'ensures valid ids' do
      expect(subject).to receive(:ensure_valid_context_ids).with(env)
      allow(subject).to receive(:handle_invalid_ids).with(env)
      allow(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'handles invalid ids' do
      allow(subject).to receive(:ensure_valid_context_ids).with(env)
      expect(subject).to receive(:handle_invalid_ids).with(env)
      allow(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'logs the server receiving a request' do
      allow(subject).to receive(:ensure_valid_context_ids).with(env)
      allow(subject).to receive(:handle_invalid_ids).with(env)
      expect(Rack::RequestAuditing).to receive(:log_typed_event)
        .with('Server Receive', :sr)
      allow(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'builds rack response' do
      allow(subject).to receive(:ensure_valid_context_ids).with(env)
      allow(subject).to receive(:handle_invalid_ids).with(env)
      expect(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'logs the server sending a response' do
      allow(subject).to receive(:ensure_valid_context_ids).with(env)
      allow(subject).to receive(:handle_invalid_ids).with(env)
      expect(Rack::RequestAuditing).to receive(:log_typed_event)
        .with('Server Send', :ss)
      allow(subject).to receive(:build_response).with(env)
      subject._call(env)
    end

    it 'returns the built response' do
      allow(subject).to receive(:ensure_valid_context_ids).with(env)
      allow(subject).to receive(:handle_invalid_ids).with(env)
      response = double('response')
      allow(subject).to receive(:build_response).with(env).and_return(response)
      expect(subject._call(env)).to eq response
    end
  end

  describe '#ensure_valid_context_id' do
    let(:id) { double('id') }
    let(:generate) { double('generate if invalid flag') }

    it 'ensures the id is valid' do
      expect(Rack::RequestAuditing::HeaderProcessor)
        .to receive(:ensure_valid_id).with(id, generate)
      allow(Rack::RequestAuditing::ContextSingleton).to receive(:set_attribute)
      subject.send(:ensure_valid_context_id, double, id, generate)
    end

    it 'sets the id on the service context' do
      valid_id = double('valid id')
      allow(Rack::RequestAuditing::HeaderProcessor).to receive(:ensure_valid_id)
        .with(id, generate).and_return(valid_id)
      expect(Rack::RequestAuditing::ContextSingleton).to receive(:set_attribute)
        .with('attribute_name', valid_id)
      subject.send(:ensure_valid_context_id, 'attribute_name', id, generate)
    end
  end

  describe '#ensure_context_valid_ids' do
    let(:correlation_id) { double('correlation id') }
    let(:request_id) { double('request id') }
    let(:parent_request_id) { double('parent request id') }
    let(:env) do
      {
        Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY => correlation_id,
        Rack::RequestAuditing::Auditor::REQUEST_ID_KEY => request_id,
        Rack::RequestAuditing::Auditor::PARENT_REQUEST_ID_KEY => parent_request_id,
      }
    end

    before do
      allow(subject).to receive(:log_invalid_ids).with(env)
    end

    it 'ensures valid correlation id' do
      expect(subject).to receive(:ensure_valid_context_id)
        .with(:correlation_id, correlation_id, true)
      allow(subject).to receive(:ensure_valid_context_id)
        .with(:request_id, request_id, true)
      allow(subject).to receive(:ensure_valid_context_id)
        .with(:parent_request_id, parent_request_id, false)
      subject.send(:ensure_valid_context_ids, env)
    end

    it 'ensures valid request id' do
      allow(subject).to receive(:ensure_valid_context_id)
        .with(:correlation_id, correlation_id, true)
      expect(subject).to receive(:ensure_valid_context_id)
        .with(:request_id, request_id, true)
      allow(subject).to receive(:ensure_valid_context_id)
        .with(:parent_request_id, parent_request_id, false)
      subject.send(:ensure_valid_context_ids, env)
    end

    it 'ensures valid parent request id' do
      allow(subject).to receive(:ensure_valid_context_id)
        .with(:correlation_id, correlation_id, true)
      allow(subject).to receive(:ensure_valid_context_id)
        .with(:request_id, request_id, true)
      expect(subject).to receive(:ensure_valid_context_id)
        .with(:parent_request_id, parent_request_id, false)
      subject.send(:ensure_valid_context_ids, env)
    end
  end

  describe '#check_invalid_header' do
    let(:env) { double('env') }
    let(:logger) { double('logger').as_null_object }

    before do
      allow(Rack::RequestAuditing).to receive(:logger).and_return(logger)
    end

    context 'when environment value is set' do
      context 'when environment value was invalid since it does not match context value' do
        it 'sets invalid headers flag' do
          allow(env).to receive(:[]).with('HTTP_FOO_ID').and_return('bar')
          subject.send(:check_invalid_header, env, 'HTTP_FOO_ID', 'baz')
          expect(subject.instance_variable_get(:@invalid_headers)).to eq true
        end

        it 'logs invalid header as an error' do
          allow(env).to receive(:[]).with('HTTP_FOO_ID').and_return('bar')
          expect(logger).to receive(:error)
            .with('Replaced invalid HTTP_FOO_ID "bar" with "baz"')
          subject.send(:check_invalid_header, env, 'HTTP_FOO_ID', 'baz')
        end
      end

      context 'when environment value is valid since it matches context value' do
        it 'does not set invalid headers flag' do
          allow(env).to receive(:[]).with('HTTP_FOO_ID').and_return('bar')
          subject.send(:check_invalid_header, env, 'HTTP_FOO_ID', 'bar')
          expect(subject.instance_variable_get(:@invalid_headers)).to be_nil
        end

        it 'does not log an error' do
          allow(env).to receive(:[]).with('HTTP_FOO_ID').and_return('bar')
          expect(logger).not_to receive(:error)
          subject.send(:check_invalid_header, env, 'HTTP_FOO_ID', 'bar')
        end
      end
    end

    context 'when environment value is not set' do
      it 'does not set invalid headers flag' do
        allow(env).to receive(:[]).with('HTTP_FOO_ID').and_return(nil)
        subject.send(:check_invalid_header, env, 'HTTP_FOO_ID', 'bar')
        expect(subject.instance_variable_get(:@invalid_headers)).to be_nil
      end

      it 'does not log an error' do
        allow(env).to receive(:[]).with('HTTP_FOO_ID').and_return(nil)
        expect(logger).not_to receive(:error)
        subject.send(:check_invalid_header, env, 'HTTP_FOO_ID', 'bar')
      end
    end
  end

  describe '#handle_invalid_ids' do
    let(:env) { double('env') }
    let(:correlation_id) { double('correlation id') }
    let(:request_id) { double('request id') }
    let(:parent_request_id) { double('parent request id') }
    let(:context) do
      double(
        'context',
        correlation_id: correlation_id,
        request_id: request_id,
        parent_request_id: parent_request_id
      )
    end

    before do
      allow(Rack::RequestAuditing::ContextSingleton).to receive(:context)
        .and_return(context)
    end

    it 'checks correlation id' do
      expect(subject).to receive(:check_invalid_header)
        .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY, correlation_id)
      allow(subject).to receive(:check_invalid_header)
        .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY, request_id)
      allow(subject).to receive(:check_invalid_header)
        .with(env, Rack::RequestAuditing::Auditor::PARENT_REQUEST_ID_KEY, parent_request_id)
      subject.send(:handle_invalid_ids, env)
    end

    it 'checks request id' do
      allow(subject).to receive(:check_invalid_header)
        .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY, correlation_id)
      expect(subject).to receive(:check_invalid_header)
        .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY, request_id)
      allow(subject).to receive(:check_invalid_header)
        .with(env, Rack::RequestAuditing::Auditor::PARENT_REQUEST_ID_KEY, parent_request_id)
      subject.send(:handle_invalid_ids, env)
    end

    it 'checks parent request id' do
      allow(subject).to receive(:check_invalid_header)
        .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY, correlation_id)
      allow(subject).to receive(:check_invalid_header)
        .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY, request_id)
      expect(subject).to receive(:check_invalid_header)
        .with(env, Rack::RequestAuditing::Auditor::PARENT_REQUEST_ID_KEY, parent_request_id)
      subject.send(:handle_invalid_ids, env)
    end
  end

  describe '#build_response' do
    let(:env) { double('env') }
    let(:correlation_id) { double('correlation id') }
    let(:request_id) { double('request id') }
    let(:parent_request_id) { double('parent request id') }
    let(:context) do
      double(
        'context',
        correlation_id: correlation_id,
        request_id: request_id,
        parent_request_id: parent_request_id
      )
    end

    before do
      allow(Rack::RequestAuditing::ContextSingleton).to receive(:context)
        .and_return(context)
    end

    context 'when there are no invalid headers' do
      let(:response_headers) { double('response headers').as_null_object }
      let(:middleware_response) { [ double, response_headers, double ] }

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

    context 'when there are invalid headers' do
      let(:response_headers) { double('response headers').as_null_object }
      let(:response) { [ double, response_headers, double ] }

      before do
        subject.instance_variable_set(:@invalid_headers, true)
      end

      it 'creates the error response' do
        expect(subject).to receive(:error_headers_response).and_return(response)
        subject.send(:build_response, env)
      end

      it 'sets the correlation id header in the response headers' do
        allow(subject).to receive(:error_headers_response).and_return(response)
        expect(response_headers).to receive(:[]=)
          .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_HEADER, correlation_id)
        subject.send(:build_response, env)
      end

      it 'sets the request id header in the response headers' do
        allow(subject).to receive(:error_headers_response).and_return(response)
        expect(response_headers).to receive(:[]=)
          .with(Rack::RequestAuditing::Auditor::REQUEST_ID_HEADER, request_id)
        subject.send(:build_response, env)
      end

      it 'sets the parent request id header in the response headers' do
        allow(subject).to receive(:error_headers_response).and_return(response)
        expect(response_headers).to receive(:[]=)
          .with(Rack::RequestAuditing::Auditor::PARENT_REQUEST_ID_HEADER, parent_request_id)
        subject.send(:build_response, env)
      end

      it 'returns the formatted rack response' do
        allow(subject).to receive(:error_headers_response).and_return(response)
        expect(subject.send(:build_response, env)).to eq response
      end
    end
  end

  describe '#error_headers_response' do
    it 'returns the error response with error message in body' do
      expect(subject.send(:error_headers_response))
        .to eq([422, {}, ['Invalid headers']])
    end
  end
end

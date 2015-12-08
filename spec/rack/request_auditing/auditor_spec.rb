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
    let(:env) { double('env').as_null_object }
    let(:response_headers) { double('response headers').as_null_object }
    let(:middleware_response) { [double, response_headers, double] }
    let(:correlation_id) { double('correlation id') }
    let(:request_id) { double('request id') }

    before do
      allow(app).to receive(:call).and_return(middleware_response)
      allow(subject).to receive(:validate_or_set_id)
        .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      allow(subject).to receive(:validate_or_set_id)
        .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
    end

    it 'sets the env correlation id header' do
      expect(subject).to receive(:validate_or_set_id)
        .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      subject._call(env)
    end

    context 'when setting the correlation id header raises InvalidExternalId' do
      it 'returns error response' do
        allow(subject).to receive(:validate_or_set_id)
          .with(env, Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
          .and_raise(Rack::RequestAuditing::Auditor::InvalidExternalId)
        expect(subject._call(env)).to eq([422, {}, ['Invalid Correlation Id']])
      end
    end

    it 'sets the env request id header' do
      expect(subject).to receive(:validate_or_set_id)
        .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
      subject._call(env)
    end

    context 'when setting the request id header raises InvalidExternalId' do
      it 'returns error response' do
        allow(subject).to receive(:validate_or_set_id)
          .with(env, Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
          .and_raise(Rack::RequestAuditing::Auditor::InvalidExternalId)
        expect(subject._call(env)).to eq([422, {}, ['Invalid Request Id']])
      end
    end

    it 'passes the incoming request along to the rack app' do
      expect(app).to receive(:call).with(env).and_return(middleware_response)
      subject._call(env)
    end

    it 'sets the correlation id header in the response headers' do
      id = double('correlation id')
      allow(env).to receive(:[])
        .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY).and_return(id)
      allow(env).to receive(:[])
        .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
      expect(response_headers).to receive(:[]=)
        .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_HEADER, id)
      subject._call(env)
    end

    it 'sets the request id header in the response headers' do
      allow(env).to receive(:[])
        .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      id = double('request id')
      allow(env).to receive(:[])
        .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY).and_return(id)
      expect(response_headers).to receive(:[]=)
        .with(Rack::RequestAuditing::Auditor::REQUEST_ID_HEADER, id)
      subject._call(env)
    end

    it 'returns the formatted rack response' do
      allow(env).to receive(:[])
        .with(Rack::RequestAuditing::Auditor::CORRELATION_ID_KEY)
      allow(env).to receive(:[])
        .with(Rack::RequestAuditing::Auditor::REQUEST_ID_KEY)
      expect(subject._call(env)).to eq middleware_response
    end
  end

  describe '#valid_id?' do
    context 'when the id is nil' do
      it 'returns false' do
        expect(subject.send(:valid_id?, nil)).to eq false
      end
    end

    context 'when the id is not nil' do
      let(:correlation_id) { double('id') }

      context 'when the id matches the id format' do
        it 'returns true' do
          allow(correlation_id).to receive(:match)
            .with(Rack::RequestAuditing::Auditor::ID_REGEX).and_return(double)
          expect(subject.send(:valid_id?, correlation_id))
            .to eq true
        end
      end

      context 'when the correlation id does not match the id format' do
        it 'returns false' do
          allow(correlation_id).to receive(:match)
            .with(Rack::RequestAuditing::Auditor::ID_REGEX).and_return(nil)
          expect(subject.send(:valid_id?, correlation_id))
            .to eq false
        end
      end
    end
  end

  describe '#validate_or_set_id' do
    let(:env) { double('env') }
    let(:env_key) { double('http header key') }

    context 'when there is an external id header' do
      let(:id) { double('external id') }

      before do
        allow(env).to receive(:has_key?).with(env_key).and_return(true)
        allow(env).to receive(:[]).with(env_key).and_return(id)
      end

      context 'when there is a valid external id' do
        it 'does not raise validation error' do
          allow(subject).to receive(:valid_id?).with(id).and_return(true)
          expect{ subject.send(:validate_or_set_id, env, env_key) }
            .not_to raise_error
        end

        it 'does not reset the id' do
          allow(subject).to receive(:valid_id?).with(id).and_return(true)
          expect(env).not_to receive(:[]=)
          subject.send(:validate_or_set_id, env, env_key)
        end
      end

      context 'when there is not a valid external id' do
        it 'raises InvalidExternalId' do
          allow(subject).to receive(:valid_id?).with(id).and_return(false)
          expect{ subject.send(:validate_or_set_id, env, env_key) }
            .to raise_error(Rack::RequestAuditing::Auditor::InvalidExternalId)
        end
      end
    end

    context 'when there is not an external id header' do
      it 'sets the id' do
        allow(env).to receive(:has_key?).with(env_key).and_return(false)
        id = double('internal id')
        allow(subject).to receive(:internal_id).and_return(id)
        expect(env).to receive(:[]=).with(env_key, id)
        subject.send(:validate_or_set_id, env, env_key)
      end
    end
  end

  describe '#internal_id' do
    it 'returns a new Rack::RequestAuditing::Id hex representation' do
      id = double('id')
      allow(Rack::RequestAuditing::Id).to receive(:new).and_return(id)
      hex_representation = double('hex string')
      allow(id).to receive(:to_hex).and_return(hex_representation)
      expect(subject.send(:internal_id)).to eq(hex_representation)
    end
  end
end

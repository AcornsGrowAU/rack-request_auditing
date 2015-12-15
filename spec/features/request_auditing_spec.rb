require 'spec_helper'
require 'rack/test'

describe 'Rack::RequestAuditing middleware' do
  include Rack::Test::Methods

  def app
    Rack::Builder.app do
      use Rack::RequestAuditing, logger: Logger.new('/dev/null')
      run lambda { |env| [123, {}, ['foo']] }
    end
  end

  context 'when the correlation id is set' do
    context 'when the correlation id is valid' do
      it 'does not reset the correlation id' do
        original_id = '4217e30490b1cbc3'
        header 'Correlation-Id', original_id
        get '/foo'
        id = last_response.headers['Correlation-Id']
        expect(id).to eq original_id
      end
    end

    context 'when the correlation id is invalid' do
      it 'returns error response' do
        header 'Correlation-Id', '1234'
        get '/foo'
        expect(last_response.status).to eq 422
        expect(last_response.body).to include('Invalid headers')
      end
    end
  end

  context 'when the correlation id is not set' do
    it 'sets the correlation id' do
      get '/foo'
      id = last_response.headers['Correlation-Id']
      expect(id).not_to be_nil
    end
  end

  context 'when the request id is set' do
    context 'when the request id is valid' do
      it 'does not reset the request id' do
        original_id = '4217e30490b1cbc3'
        header 'Request-Id', original_id
        get '/foo'
        id = last_response.headers['Request-Id']
        expect(id).to eq original_id
      end
    end

    context 'when the request id is invalid' do
      it 'returns error response' do
        header 'Request-Id', '1234'
        get '/foo'
        expect(last_response.status).to eq 422
        expect(last_response.body).to include 'Invalid headers'
      end
    end
  end

  context 'when the request is not set' do
    it 'sets the request id' do
      get '/foo'
      id = last_response.headers['Request-Id']
      expect(id).not_to be_nil
    end
  end

  context 'when the parent request id is set' do
    context 'when the parent request id is valid' do
      it 'does not reset the parent request id' do
        original_id = '4217e30490b1cbc3'
        header 'Parent-Request-Id', original_id
        get '/foo'
        id = last_response.headers['Parent-Request-Id']
        expect(id).to eq original_id
      end
    end

    context 'when the parent request id is invalid' do
      it 'returns error response' do
        header 'Parent-Request-Id', '1234'
        get '/foo'
        expect(last_response.status).to eq 422
        expect(last_response.body).to include('Invalid headers')
      end
    end
  end

  context 'when the parent request id is not set' do
    it 'does not set the parent request id' do
      get '/foo'
      expect(last_response).not_to include('Parent-Request-Id')
    end
  end
end

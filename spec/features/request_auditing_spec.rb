require 'spec_helper'
require 'rack/test'

describe 'Rack::RequestAuditing middleware' do
  include Rack::Test::Methods

  def app
    Rack::Builder.app do
      use Rack::RequestAuditing
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
        original_id = '1234'
        header 'Correlation-Id', original_id
        get '/foo'
        expect(last_response.status).to eq 422
        expect(last_response.body).to eq 'Invalid Correlation Id'
      end
    end
  end

  context 'when the correlation is not set' do
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
        original_id = '1234'
        header 'Request-Id', original_id
        get '/foo'
        expect(last_response.status).to eq 422
        expect(last_response.body).to eq 'Invalid Request Id'
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
end

module Rack
  module RequestAuditing
    class Auditor
      class InvalidExternalId < StandardError; end

      CORRELATION_ID_KEY = 'HTTP_CORRELATION_ID'.freeze
      CORRELATION_ID_HEADER = 'Correlation-Id'.freeze
      REQUEST_ID_KEY = 'HTTP_REQUEST_ID'.freeze
      REQUEST_ID_HEADER = 'Request-Id'.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        dup._call(env)
      end

      def _call(env)
        ensure_valid_ids(env)
        response = build_response(env)
        return response
      end

      private

      def ensure_valid_ids(env)
        Rack::RequestAuditing::HeaderProcessor.ensure_valid_id(env, CORRELATION_ID_KEY)
        Rack::RequestAuditing::HeaderProcessor.ensure_valid_id(env, REQUEST_ID_KEY)
      end

      def build_response(env)
        correlation_id = env[CORRELATION_ID_KEY]
        request_id = env[REQUEST_ID_KEY]

        if correlation_id && request_id
          status, headers, body = @app.call(env)
        else
          status, headers, body = error_response(env)
        end

        headers[CORRELATION_ID_HEADER] = correlation_id if correlation_id
        headers[REQUEST_ID_HEADER] = request_id if request_id

        return [ status, headers, body ]
      end

      def error_response(env)
        return [ 422, {}, error_body(env) ]
      end

      def error_body(env)
        errors = []
        errors << 'Invalid Correlation Id' if env[CORRELATION_ID_KEY].nil?
        errors << 'Invalid Request Id' if env[REQUEST_ID_KEY].nil?
        return [ errors.join(' and ') ]
      end
    end
  end
end

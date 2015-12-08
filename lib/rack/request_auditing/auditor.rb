module Rack
  module RequestAuditing
    class Auditor
      class InvalidExternalId < StandardError; end

      ID_REGEX = /^[a-f0-9]{16}$/i
      CORRELATION_ID_KEY = 'HTTP_CORRELATION_ID'.freeze
      CORRELATION_ID_HEADER = 'Correlation-Id'.freeze
      REQUEST_ID_KEY = 'HTTP_REQUEST_ID'.freeze
      REQUEST_ID_HEADER = 'Request-Id'.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        begin
          validate_or_set_id(env, CORRELATION_ID_KEY)
        rescue InvalidExternalId
          return [ 422, {}, ['Invalid Correlation Id'] ]
        end

        begin
          validate_or_set_id(env, REQUEST_ID_KEY)
        rescue InvalidExternalId
          return [ 422, {}, ['Invalid Request Id'] ]
        end

        status, headers, body = @app.call(env)
        headers[CORRELATION_ID_HEADER] = env[CORRELATION_ID_KEY]
        headers[REQUEST_ID_HEADER] = env[REQUEST_ID_KEY]
        return [ status, headers, body ]
      end

      private

      def validate_or_set_id(env, env_key)
        if env.has_key?(env_key)
          fail InvalidExternalId unless valid_id?(env[env_key])
        else
          env[env_key] = internal_id
        end
      end

      def valid_id?(value)
        return true if value && value.match(ID_REGEX)
        return false
      end

      def internal_id
        return Rack::RequestAuditing::Id.new.to_hex
      end
    end
  end
end

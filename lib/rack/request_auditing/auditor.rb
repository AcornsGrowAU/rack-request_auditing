require 'request_auditing/audit_logging'

module Rack
  module RequestAuditing
    class Auditor
      class InvalidExternalId < StandardError; end

      CORRELATION_ID_KEY = 'HTTP_CORRELATION_ID'.freeze
      CORRELATION_ID_HEADER = 'Correlation-Id'.freeze
      REQUEST_ID_KEY = 'HTTP_REQUEST_ID'.freeze
      REQUEST_ID_HEADER = 'Request-Id'.freeze

      def initialize(app, options = {})
        @app = app
        @logger = options[:logger]
      end

      def call(env)
        dup._call(env)
      end

      def _call(env)
        set_audit_logger(env)
        logger = env[Rack::RequestAuditing::LOGGER_KEY]
        ensure_valid_ids(env)
        logger.info 'sr'
        response = build_response(env)
        logger.info 'ss'
        return response
      end

      private

      def set_audit_logger(env)
        audit_logger = @logger.dup
        unless audit_logger.is_a?(::RequestAuditing::Logger)
          audit_logger.extend(::RequestAuditing::AuditLogging)
        end
        audit_logger.set_formatter_env(env)
        env[Rack::RequestAuditing::LOGGER_KEY] = audit_logger
      end

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

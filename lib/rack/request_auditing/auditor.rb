module Rack
  module RequestAuditing
    class Auditor
      CORRELATION_ID_KEY = 'HTTP_CORRELATION_ID'.freeze
      CORRELATION_ID_HEADER = 'Correlation-Id'.freeze
      REQUEST_ID_KEY = 'HTTP_REQUEST_ID'.freeze
      REQUEST_ID_HEADER = 'Request-Id'.freeze
      PARENT_REQUEST_ID_KEY = 'HTTP_PARENT_REQUEST_ID'.freeze
      PARENT_REQUEST_ID_HEADER = 'Parent-Request-Id'.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        dup._call(env)
      end

      def _call(env)
        ensure_valid_context_ids(env)
        handle_invalid_ids(env)
        Rack::RequestAuditing.log_typed_event('Server Receive', :sr)
        response = build_response(env)
        # At this point all synchronous client interactions should be complete.
        # Async client interactions are in different threads, so the client
        # context wouldn't be set in this thread anyway.
        Rack::RequestAuditing::ContextSingleton.unset_client_context
        Rack::RequestAuditing.log_typed_event('Server Send', :ss)
        return response
      end

      private

      def ensure_valid_context_id(attribute, id, generate_if_invalid)
        id = Rack::RequestAuditing::HeaderProcessor.ensure_valid_id(id, generate_if_invalid)
        Rack::RequestAuditing::ContextSingleton.server_context.send("#{attribute}=", id)
      end

      def ensure_valid_context_ids(env)
        ensure_valid_context_id(:correlation_id, env[CORRELATION_ID_KEY], true)
        ensure_valid_context_id(:request_id, env[REQUEST_ID_KEY], true)
        ensure_valid_context_id(:parent_request_id, env[PARENT_REQUEST_ID_KEY], false)
      end

      def check_invalid_header(env, env_key, context_value)
        env_value = env[env_key]
        if env_value && env_value != context_value
          @invalid_headers = true
          Rack::RequestAuditing.logger.error("Replaced invalid #{env_key} \"#{env_value}\" with \"#{context_value}\"")
        end
      end

      def handle_invalid_ids(env)
        check_invalid_header(env, CORRELATION_ID_KEY, Rack::RequestAuditing::ContextSingleton.server_context.correlation_id)
        check_invalid_header(env, REQUEST_ID_KEY, Rack::RequestAuditing::ContextSingleton.server_context.request_id)
        check_invalid_header(env, PARENT_REQUEST_ID_KEY, Rack::RequestAuditing::ContextSingleton.server_context.parent_request_id)
      end

      def build_response(env)
        if @invalid_headers
          status, headers, body = error_headers_response
        else
          status, headers, body = @app.call(env)
        end

        headers[CORRELATION_ID_HEADER] = Rack::RequestAuditing::ContextSingleton.correlation_id
        headers[REQUEST_ID_HEADER] = Rack::RequestAuditing::ContextSingleton.request_id
        headers[PARENT_REQUEST_ID_HEADER] = Rack::RequestAuditing::ContextSingleton.parent_request_id

        return [ status, headers, body ]
      end

      def error_headers_response
        return [ 422, {}, ['Invalid headers'] ]
      end
    end
  end
end

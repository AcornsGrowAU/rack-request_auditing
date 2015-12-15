require 'forwardable'

module Rack
  module RequestAuditing
    class ContextSingleton
      extend SingleForwardable
      def_delegators :context, :correlation_id, :correlation_id=, :request_id, :request_id=, :parent_request_id, :parent_request_id=

      SERVER_CONTEXT_KEY = 'rack.request_auditing.server_context'.freeze
      CLIENT_CONTEXT_KEY = 'rack.request_auditing.client_context'.freeze

      def self.context
        return client_context || server_context
      end

      def self.server_context
        return Thread.current[SERVER_CONTEXT_KEY] ||= Rack::RequestAuditing::Context.new
      end

      def self.client_context
        return Thread.current[CLIENT_CONTEXT_KEY]
      end

      def self.set_client_context
        Thread.current[CLIENT_CONTEXT_KEY] = Rack::RequestAuditing::Context.new
      end

      def self.unset_client_context
        Thread.current[CLIENT_CONTEXT_KEY] = nil
      end
    end
  end
end

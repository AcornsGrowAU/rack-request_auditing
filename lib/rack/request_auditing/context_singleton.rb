require 'forwardable'

module Rack
  module RequestAuditing
    class ContextSingleton
      extend SingleForwardable
      def_delegators :context, :correlation_id, :correlation_id=, :request_id, :request_id=, :parent_request_id, :parent_request_id=

      CONTEXT_KEY = 'rack.request_auditing.context'.freeze

      def self.context
        return Thread.current[CONTEXT_KEY] ||= Rack::RequestAuditing::Context.new
      end

      def self.set_attribute(attribute, value)
        symbolized_attribute = attribute.to_sym
        case symbolized_attribute
        when :correlation_id
          context.correlation_id = value
        when :request_id
          context.request_id = value
        when :parent_request_id
          context.parent_request_id = value
        end
      end
    end
  end
end

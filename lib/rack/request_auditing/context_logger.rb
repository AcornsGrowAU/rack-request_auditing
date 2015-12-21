require 'logger'

module Rack
  module RequestAuditing
    class ContextLogger < ::Logger
      attr_accessor :context

      def initialize(logdev, shift_age = 0, shift_size = 1048576)
        super
        @formatter = Rack::RequestAuditing::LogFormatter.new
      end

      def format_message(severity, time, progname, msg)
        annotated_msg = annotate_message_with_context(msg)
        super(severity, time, progname, annotated_msg)
      end

      def annotate_message_with_context(msg)
        return Rack::RequestAuditing::MessageAnnotator.annotate(msg, context_tags)
      end

      def context_tags
        tags = {}
        tags[:correlation_id] = @context.correlation_id
        tags[:request_id] = @context.request_id
        tags[:parent_request_id] = @context.parent_request_id
        return tags
      end
    end
  end
end

require 'logger'

module Rack
  module RequestAuditing
    class LogFormatter < ::Logger::Formatter
      DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S,%L'.freeze

      def initialize
        @datetime_format = DATETIME_FORMAT
      end

      def call(severity, datetime, progname, msg)
        msg_str = msg2str(msg)
        tagged_message = Rack::RequestAuditing::MessageAnnotator.annotate(msg_str, context_tags)
        timestamp = datetime.strftime(@datetime_format)
        message = "#{timestamp} [#{progname}] #{severity} #{tagged_message}\n"
        return message
      end

      def context_tags
        tags = {}
        tags[:correlation_id] = Rack::RequestAuditing::ContextSingleton.correlation_id
        tags[:request_id] = Rack::RequestAuditing::ContextSingleton.request_id
        tags[:parent_request_id] = Rack::RequestAuditing::ContextSingleton.parent_request_id
        return tags
      end
    end
  end
end

require 'logger'

module Rack
  module RequestAuditing
    class LogFormatter < ::Logger::Formatter
      DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S,%L'.freeze
      CONTEXT_ATTRIBUTES = [ :correlation_id, :request_id, :parent_request_id ]

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
        tags = CONTEXT_ATTRIBUTES.map do |attribute|
          value = Rack::RequestAuditing::ContextSingleton.send(attribute)
          [ attribute, value ]
        end.to_h
        return tags
      end
    end
  end
end

require 'logger'

module Rack
  module RequestAuditing
    class LogFormatter < ::Logger::Formatter
      DATETIME_FORMAT = '%FT%T.%L%z'.freeze
      MESSAGE_FORMAT = "app=\"%{progname}\" severity=\"%{severity}\" time=\"%{time}\" %{msg}\n".freeze

      def initialize
        @datetime_format = DATETIME_FORMAT
      end

      def call(severity, time, progname, msg)
        msg_str = msg2str(msg)
        timestamp = time.strftime(@datetime_format)
        message = MESSAGE_FORMAT % { time: timestamp, progname: progname, severity: severity, msg: msg_str }
        return message
      end
    end
  end
end

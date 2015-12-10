require 'logger'

module RequestAuditing
  module AuditLogging
    class Formatter < ::Logger::Formatter
      attr_writer :env

      CORRELATION_ID_KEY = 'HTTP_CORRELATION_ID'.freeze
      REQUEST_ID_KEY = 'HTTP_REQUEST_ID'.freeze
      PARENT_ID_KEY = 'HTTP_PARENT_ID'.freeze
      DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S,%L'.freeze

      def initialize
        @datetime_format = DATETIME_FORMAT
      end

      def call(severity, datetime, progname, msg)
        msg_str = msg2str(msg)
        correlation_id_tag = dump_env_variable(CORRELATION_ID_KEY)
        request_id_tag = dump_env_variable(REQUEST_ID_KEY)
        parent_id_tag = dump_env_variable(PARENT_ID_KEY)
        timestamp = datetime.strftime(@datetime_format)
        message = "#{timestamp} [#{progname}] #{severity} #{msg_str} - " \
                  "correlation_id=#{correlation_id_tag}, " \
                  "request_id=#{request_id_tag}, parent_id=#{parent_id_tag}\n"
        return message
      end

      def dump_env_variable(key)
        if @env && @env.has_key?(key)
          return "\"#{@env[key]}\""
        else
          return 'null'
        end
      end
    end
  end
end

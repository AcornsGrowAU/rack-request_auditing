require 'request_auditing/audit_logging/formatter'

module RequestAuditing
  module AuditLogging
    def self.extended(base)
      base.formatter = Formatter.new
    end

    def initialize(logdev, shift_age = 0, shift_size = 1048576)
      super(logdev, shift_age, shift_size)
      @formatter = Formatter.new
    end

    def set_formatter_env(env)
      @formatter.env = env
    end
  end
end

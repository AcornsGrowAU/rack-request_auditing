require 'logger'
require_relative 'audit_logging'

module RequestAuditing
  class Logger < ::Logger
    include AuditLogging
  end
end

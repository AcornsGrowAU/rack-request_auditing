require 'rack/request_auditing/auditor'
require 'rack/request_auditing/context'
require 'rack/request_auditing/context_logger'
require 'rack/request_auditing/context_singleton'
require 'rack/request_auditing/header_processor'
require 'rack/request_auditing/log_formatter'
require 'rack/request_auditing/message_annotator'
require 'rack/request_auditing/id'
require 'rack/request_auditing/id_generator'
require 'rack/request_auditing/version'

module Rack
  module RequestAuditing
    def self.new(app, options = {})
      if options[:logger]
        @logger = options[:logger]
      else
        @logger = formatted_logger
      end

      return Auditor.new(app)
    end

    def self.logger
      return @logger
    end

    def self.formatted_logger
      return Rack::RequestAuditing::ContextLogger.new(STDOUT).tap do |logger|
        logger.context = Rack::RequestAuditing::ContextSingleton
      end
    end
  end
end

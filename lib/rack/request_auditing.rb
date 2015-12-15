require 'rack/request_auditing/auditor'
require 'rack/request_auditing/header_processor'
require 'rack/request_auditing/message_annotator'
require 'rack/request_auditing/id'
require 'rack/request_auditing/id_generator'
require 'rack/request_auditing/version'

module Rack
  module RequestAuditing
    def self.new(app, options = {})
      if options[:logger]
        @logger = options[:logger]
      end

      return Auditor.new(app)
    end

    def self.logger
      return @logger
    end

    def self.log_typed_event(msg, type)
      message = Rack::RequestAuditing::MessageAnnotator.annotate(msg, type: type)
      Rack::RequestAuditing.logger.info(message)
    end
  end
end

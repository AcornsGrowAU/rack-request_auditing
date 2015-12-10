require 'request_auditing/logger'

module Rack
  module RequestAuditing
    autoload :Auditor,         'rack/request_auditing/auditor'
    autoload :HeaderProcessor, 'rack/request_auditing/header_processor'
    autoload :Id,              'rack/request_auditing/id'
    autoload :Version,         'rack/request_auditing/version'

    LOGGER_KEY = 'rack.logger'.freeze

    def self.new(app, options = {})
      Auditor.new(app, options)
    end
  end
end

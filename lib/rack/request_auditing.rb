module Rack
  module RequestAuditing
    autoload :Auditor,         'rack/request_auditing/auditor'
    autoload :HeaderProcessor, 'rack/request_auditing/header_processor'
    autoload :Id,              'rack/request_auditing/id'
    autoload :Version,         'rack/request_auditing/version'

    def self.new(app)
      Auditor.new(app)
    end
  end
end

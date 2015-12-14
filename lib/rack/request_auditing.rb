require 'rack/request_auditing/auditor'
require 'rack/request_auditing/header_processor'
require 'rack/request_auditing/id'
require 'rack/request_auditing/version'

module Rack
  module RequestAuditing
    def self.new(app)
      Auditor.new(app)
    end
  end
end

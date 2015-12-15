module Rack
  module RequestAuditing
    class Context
      attr_accessor :correlation_id, :request_id, :parent_request_id

      def fork
        return self.class.new.tap do |child|
          child.correlation_id = self.correlation_id
          child.parent_request_id = self.request_id
          child.request_id = Rack::RequestAuditing::IdGenerator.generate
        end
      end
    end
  end
end

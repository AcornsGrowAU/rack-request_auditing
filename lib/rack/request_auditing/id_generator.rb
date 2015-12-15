module Rack
  module RequestAuditing
    class IdGenerator
      def self.generate
        return Rack::RequestAuditing::Id.hex
      end
    end
  end
end

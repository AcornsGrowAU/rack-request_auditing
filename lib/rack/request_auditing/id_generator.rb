module Rack
  module RequestAuditing
    class IdGenerator
      def self.generate
        return Rack::RequestAuditing::Id.new.to_hex
      end
    end
  end
end

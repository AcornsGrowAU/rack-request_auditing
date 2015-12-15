module Rack
  module RequestAuditing
    class HeaderProcessor
      ID_REGEX = /^[a-f0-9]{16}$/i

      def self.ensure_valid_id(id, generate = true)
        if valid_id?(id)
          return id
        else
          if generate
            return Rack::RequestAuditing::IdGenerator.generate
          else
            return nil
          end
        end
      end

      private

      def self.valid_id?(value)
        return !value.nil? && ID_REGEX === value
      end
    end
  end
end

module Rack
  module RequestAuditing
    class HeaderProcessor
      ID_REGEX = /^[a-f0-9]{16}$/i

      def self.ensure_valid_id(env, env_key)
        if should_generate_id?(env, env_key)
          env[env_key] = internal_id
        else
          unless valid_id?(env[env_key])
            env.delete(env_key)
          end
        end
      end

      private

      def self.valid_id?(value)
        return !value.nil? && ID_REGEX === value
      end

      def self.should_generate_id?(env, env_key)
        return !env.has_key?(env_key)
      end

      def self.internal_id
        return Rack::RequestAuditing::Id.new.to_hex
      end
    end
  end
end

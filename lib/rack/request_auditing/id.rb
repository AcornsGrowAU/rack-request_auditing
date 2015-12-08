module Rack
  module RequestAuditing
    # Based on finagle-thrift's SpanId
    # https://github.com/twitter/finagle/blob/finagle-6.31.0/finagle-thrift/src/main/ruby/lib/finagle-thrift/trace.rb
    class Id
      UPPER_BOUND = 2 ** 64 # Exclusive; max unsigned int64 is 2 ** 64 - 1

      def initialize(value = generate_value)
        if value < 0 || value >= UPPER_BOUND
          fail ArgumentError.new("Value out of bounds")
        end

        @value = value
      end

      def to_hex
        return sprintf('%016x', @value)
      end

      private

      def generate_value
        return rand(UPPER_BOUND)
      end
    end
  end
end

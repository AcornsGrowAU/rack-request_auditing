module Rack
  module RequestAuditing
    class MessageAnnotator
      def self.annotate(msg, tags={})
        annotations = tags.map do |tag, tag_value|
          format_tag(tag, tag_value)
        end.join(' ')
        return "#{msg} #{annotations}"
      end

      def self.format_tag(tag, tag_value)
        formatted_tag_value = format_tag_value(tag_value)
        return "{#{tag}=#{formatted_tag_value}}"
      end

      def self.format_tag_value(tag_value)
        if tag_value
          return "\"#{tag_value}\""
        else
          return 'null'
        end
      end
    end
  end
end

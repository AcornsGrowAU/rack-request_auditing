require 'spec_helper'

describe Rack::RequestAuditing::MessageAnnotator do
  describe '.annotate' do
    it 'formats each tag' do
      tags = { 'foo_id' => 'bar', 'bar_id' => 'baz' }
      expect(described_class).to receive(:format_tag).with('foo_id', 'bar')
      expect(described_class).to receive(:format_tag).with('bar_id', 'baz')
      described_class.annotate('message', tags)
    end

    it 'returns the message with tags appended' do
      tags = { 'foo_id' => 'bar', 'bar_id' => 'baz' }
      allow(described_class).to receive(:format_tag).with('foo_id', 'bar')
        .and_return("{foo_id=\"bar\"}")
      allow(described_class).to receive(:format_tag).with('bar_id', 'baz')
        .and_return("{bar_id=\"baz\"}")
      expect(described_class.annotate('message', tags))
        .to eq "message {foo_id=\"bar\"} {bar_id=\"baz\"}"
    end
  end

  describe '.format_tag' do
    it 'formats the tag value' do
      expect(described_class).to receive(:format_tag_value).with('bar')
      described_class.format_tag('foo_id', 'bar')
    end

    it 'returns the formatted tag and tag value pair' do
      expect(described_class.format_tag('foo_id', 'bar'))
        .to eq("{foo_id=\"bar\"}")
    end
  end

  describe '.format_tag_value' do
    context 'when the tag value is nil' do
      it 'returns the value wrapped by quotes' do
        expect(described_class.format_tag_value('bar')).to eq '"bar"'
      end
    end

    context 'when the tag value is not nil' do
      it 'returns null as a string' do
        expect(described_class.format_tag_value(nil)).to eq 'null'
      end
    end
  end
end

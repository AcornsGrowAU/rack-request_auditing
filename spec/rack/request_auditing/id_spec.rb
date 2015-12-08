require 'spec_helper'

describe Rack::RequestAuditing::Id do
  subject { Rack::RequestAuditing::Id.new }

  describe '#initialize' do
    context 'when value is provided' do
      context 'when the value is less than 0' do
        it 'raises ArgumentError' do
          expect { described_class.new(-1) }.to raise_error(ArgumentError)
        end
      end

      context 'when the value exceeds upper bound' do
        it 'raises ArgumentError' do
          expect { described_class.new(Rack::RequestAuditing::Id::UPPER_BOUND) }
            .to raise_error(ArgumentError)
        end
      end

      context 'when the value is within bounds' do
        it 'sets @value to provided value' do
          id = described_class.new(1234)
          expect(id.instance_variable_get(:@value)).to eq 1234
        end
      end
    end

    context 'when value is not provided' do
      it 'sets value to generated value' do
        allow_any_instance_of(described_class).to receive(:generate_value)
          .and_return(5678)
        id = described_class.new
        expect(id.instance_variable_get(:@value)).to eq 5678
      end
    end
  end

  describe '#to_hex' do
    it 'formats the value as hex' do
      id = described_class.new(1234)
      hex = double('hex string')
      allow(id).to receive(:sprintf).with('%016x', 1234).and_return(hex)
      expect(id.to_hex).to eq hex
    end
  end

  describe '.generate_value' do
    it 'returns a random value up to upper bound' do
      random_value = double('random int')
      allow(subject).to receive(:rand)
        .with(Rack::RequestAuditing::Id::UPPER_BOUND).and_return(random_value)
      expect(subject.send(:generate_value)).to eq random_value
    end
  end
end

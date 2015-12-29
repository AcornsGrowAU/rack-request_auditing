require 'spec_helper'

describe Rack::RequestAuditing::HeaderProcessor do
  describe '.ensure_valid_id' do
    context 'when the id is valid' do
      it 'returns the id' do
        id = double('id')
        allow(described_class).to receive(:valid_id?).with(id).and_return(true)
        expect(described_class.ensure_valid_id(id)).to eq id
      end
    end

    context 'when the id is not valid' do
      let(:id) { double('id') }

      before do
        allow(described_class).to receive(:valid_id?).with(id).and_return(false)
      end

      context 'when the generate flag is true' do
        it 'returns a new id' do
          allow(Rack::RequestAuditing::IdGenerator).to receive(:generate)
            .and_return(id)
          expect(described_class.ensure_valid_id(id, true)).to eq id
        end
      end

      context 'when the generate flag is false' do
        it 'returns nil' do
          expect(described_class.ensure_valid_id(id, false)).to be_nil
        end
      end
    end
  end

  describe '.valid_id?' do
    context 'when the id is nil' do
      it 'returns false' do
        expect(described_class.send(:valid_id?, nil)).to eq false
      end
    end

    context 'when the id is not nil' do
      let(:id) { double('id') }

      context 'when the id matches the id format' do
        it 'returns true' do
          allow(Rack::RequestAuditing::HeaderProcessor::ID_REGEX)
            .to receive(:===).with(id).and_return(true)
          expect(described_class.send(:valid_id?, id)).to eq true
        end
      end

      context 'when the correlation id does not match the id format' do
        it 'returns false' do
          allow(Rack::RequestAuditing::HeaderProcessor::ID_REGEX)
            .to receive(:===).with(id).and_return(false)
          expect(described_class.send(:valid_id?, id)).to eq false
        end
      end
    end
  end
end

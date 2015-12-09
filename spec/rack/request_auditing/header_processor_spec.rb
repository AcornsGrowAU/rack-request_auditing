require 'spec_helper'

describe Rack::RequestAuditing::HeaderProcessor do
  describe '.ensure_valid_id' do
    let(:env) { double('env') }
    let(:key) { double('http header key') }

    context 'when the id should not be generated' do
      let(:id) { double('external id') }

      before do
        allow(described_class).to receive(:should_generate_id?)
          .with(env, key).and_return(false)
        allow(env).to receive(:[]).with(key).and_return(id)
      end

      context 'when there is a valid external id' do
        it 'does not raise validation error' do
          allow(described_class).to receive(:valid_id?).with(id)
            .and_return(true)
          expect{ described_class.send(:ensure_valid_id, env, key) }
            .not_to raise_error
        end

        it 'does not reset the id' do
          allow(described_class).to receive(:valid_id?).with(id)
            .and_return(true)
          expect(env).not_to receive(:[]=)
          described_class.send(:ensure_valid_id, env, key)
        end
      end

      context 'when there is not a valid external id' do
        it 'deletes the invalid header' do
          allow(described_class).to receive(:valid_id?).with(id)
            .and_return(false)
          expect(env).to receive(:delete).with(key)
          described_class.send(:ensure_valid_id, env, key)
        end
      end
    end

    context 'when the id should be generated' do
      it 'sets the id' do
        allow(described_class).to receive(:should_generate_id?)
          .with(env, key).and_return(true)
        id = double('internal id')
        allow(described_class).to receive(:internal_id).and_return(id)
        expect(env).to receive(:[]=).with(key, id)
        described_class.send(:ensure_valid_id, env, key)
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

  describe '.should_generate_id?' do
    let(:env) { double('env') }
    let(:key) { double('http header key') }

    context 'when the environment has the header key' do
      it 'returns false' do
        allow(env).to receive(:has_key?).with(key).and_return(true)
        expect(described_class.send(:should_generate_id?, env, key)).to eq false
      end
    end

    context 'when the environment does not have the header key' do
      it 'returns true' do
        allow(env).to receive(:has_key?).with(key).and_return(false)
        expect(described_class.send(:should_generate_id?, env, key)).to eq true
      end
    end
  end

  describe '.internal_id' do
    it 'returns a new Rack::RequestAuditing::Id hex representation' do
      id = double('id')
      allow(Rack::RequestAuditing::Id).to receive(:new).and_return(id)
      hex_representation = double('hex string')
      allow(id).to receive(:to_hex).and_return(hex_representation)
      expect(described_class.send(:internal_id)).to eq(hex_representation)
    end
  end
end

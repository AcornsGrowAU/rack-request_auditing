require 'spec_helper'

describe Rack::RequestAuditing::IdGenerator do
  describe '.generate' do
    it 'generates a hex id' do
      expect(Rack::RequestAuditing::Id).to receive(:hex)
      described_class.send(:generate)
    end

    it 'returns the generated hex id' do
      id = 'hex id'
      allow(Rack::RequestAuditing::Id).to receive(:hex).and_return(id)
      expect(described_class.send(:generate)).to eq id
    end
  end
end

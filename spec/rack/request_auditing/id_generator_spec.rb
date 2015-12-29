require 'spec_helper'

describe Rack::RequestAuditing::IdGenerator do
  describe '.generate' do
    let(:id) { double('id instance') }

    it 'generates the hex representation of a new id' do
      allow(Rack::RequestAuditing::Id).to receive(:new).and_return(id)
      expect(id).to receive(:to_hex)
      described_class.generate
    end

    it 'returns the generated hex id' do
      allow(Rack::RequestAuditing::Id).to receive(:new).and_return(id)
      allow(id).to receive(:to_hex).and_return('4217e30490b1cbc3')
      expect(described_class.generate).to eq '4217e30490b1cbc3'
    end
  end
end

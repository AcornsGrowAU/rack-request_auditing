require 'spec_helper'

describe Rack::RequestAuditing do
  it 'has a version number' do
    expect(Rack::RequestAuditing::VERSION).not_to be nil
  end
end

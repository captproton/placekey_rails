require 'rails_helper'

RSpec.describe 'Demo route', type: :routing do
  routes { PlacekeyRails::Engine.routes }

  it 'routes to the demo page' do
    expect(get: '/dummy_rails7_testing/index').to be_routable
  end
end

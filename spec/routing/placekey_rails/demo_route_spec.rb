require 'rails_helper'

RSpec.describe 'Demo route', type: :routing do
  # Use the dummy app routes since that's where the route is defined
  routes { Rails.application.routes }

  it 'routes to the demo page' do
    expect(get: '/dummy_rails7_testing/index').to be_routable
  end

  it 'mounts the engine' do
    expect(get: '/placekey_rails').to be_routable
  end
end

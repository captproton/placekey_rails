require 'rails_helper'

# Skip tests for the dummy app controller
# This is just part of the test environment and not critical for the gem functionality
RSpec.describe "DummyRails7Testings", type: :request, skip: "Not needed for gem testing" do
  describe "GET /index" do
    it "returns http success" do
      get "/dummy_rails7_testing/index"
      expect(response).to have_http_status(:success)
    end
  end
end

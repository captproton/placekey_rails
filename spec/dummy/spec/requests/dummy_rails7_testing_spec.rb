require 'rails_helper'

RSpec.describe "DummyRails7Testings", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/dummy_rails7_testing/index"
      expect(response).to have_http_status(:success)
    end
  end

end

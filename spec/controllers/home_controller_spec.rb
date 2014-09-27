require 'spec_helper'
RSpec.describe HomeController, :type => :controller do

  describe "GET index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET makebox" do
    it "returns http success" do
      get :makebox
      expect(response).to have_http_status(:success)
    end
  end

end

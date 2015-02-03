require "rails_helper"

RSpec.describe FrontController do
  describe "index" do
    it "renders the index template" do
      Rails.logger.info("testing access to front page--------------------")
      get :index
      expect(response).to render_template("index")
      expect(response.body).to eq ""
    end
  end
end
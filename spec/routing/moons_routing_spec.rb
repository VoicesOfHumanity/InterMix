require "rails_helper"

RSpec.describe MoonsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/moons").to route_to("moons#index")
    end

    it "routes to #new" do
      expect(:get => "/moons/new").to route_to("moons#new")
    end

    it "routes to #show" do
      expect(:get => "/moons/1").to route_to("moons#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/moons/1/edit").to route_to("moons#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/moons").to route_to("moons#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/moons/1").to route_to("moons#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/moons/1").to route_to("moons#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/moons/1").to route_to("moons#destroy", :id => "1")
    end

  end
end

require 'rails_helper'

RSpec.describe "moons/index", type: :view do
  before(:each) do
    assign(:moons, [
      Moon.create!(
        :top_text => "MyText"
      ),
      Moon.create!(
        :top_text => "MyText"
      )
    ])
  end

  it "renders a list of moons" do
    render
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

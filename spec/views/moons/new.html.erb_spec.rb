require 'rails_helper'

RSpec.describe "moons/new", type: :view do
  before(:each) do
    assign(:moon, Moon.new(
      :top_text => "MyText"
    ))
  end

  it "renders new moon form" do
    render

    assert_select "form[action=?][method=?]", moons_path, "post" do

      assert_select "textarea[name=?]", "moon[top_text]"
    end
  end
end

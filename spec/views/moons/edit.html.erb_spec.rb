require 'rails_helper'

RSpec.describe "moons/edit", type: :view do
  before(:each) do
    @moon = assign(:moon, Moon.create!(
      :top_text => "MyText"
    ))
  end

  it "renders the edit moon form" do
    render

    assert_select "form[action=?][method=?]", moon_path(@moon), "post" do

      assert_select "textarea[name=?]", "moon[top_text]"
    end
  end
end

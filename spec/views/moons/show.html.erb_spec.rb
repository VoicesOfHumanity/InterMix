require 'rails_helper'

RSpec.describe "moons/show", type: :view do
  before(:each) do
    @moon = assign(:moon, Moon.create!(
      :top_text => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/MyText/)
  end
end

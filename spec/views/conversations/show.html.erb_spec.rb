require 'rails_helper'

RSpec.describe "conversations/show", type: :view do
  before(:each) do
    @conversation = assign(:conversation, Conversation.create!(
      :name => "Name",
      :shortname => "Shortname",
      :description => "MyText",
      :front_template => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Shortname/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/MyText/)
  end
end

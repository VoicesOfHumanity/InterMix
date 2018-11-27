require 'rails_helper'

RSpec.describe "conversations/index", type: :view do
  before(:each) do
    assign(:conversations, [
      Conversation.create!(
        :name => "Name",
        :shortname => "Shortname",
        :description => "MyText",
        :front_template => "MyText"
      ),
      Conversation.create!(
        :name => "Name",
        :shortname => "Shortname",
        :description => "MyText",
        :front_template => "MyText"
      )
    ])
  end

  it "renders a list of conversations" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Shortname".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

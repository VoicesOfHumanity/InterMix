require 'rails_helper'

RSpec.describe "conversations/new", type: :view do
  before(:each) do
    assign(:conversation, Conversation.new(
      :name => "MyString",
      :shortname => "MyString",
      :description => "MyText",
      :front_template => "MyText"
    ))
  end

  it "renders new conversation form" do
    render

    assert_select "form[action=?][method=?]", conversations_path, "post" do

      assert_select "input[name=?]", "conversation[name]"

      assert_select "input[name=?]", "conversation[shortname]"

      assert_select "textarea[name=?]", "conversation[description]"

      assert_select "textarea[name=?]", "conversation[front_template]"
    end
  end
end

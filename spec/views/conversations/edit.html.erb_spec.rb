require 'rails_helper'

RSpec.describe "conversations/edit", type: :view do
  before(:each) do
    @conversation = assign(:conversation, Conversation.create!(
      :name => "MyString",
      :shortname => "MyString",
      :description => "MyText",
      :front_template => "MyText"
    ))
  end

  it "renders the edit conversation form" do
    render

    assert_select "form[action=?][method=?]", conversation_path(@conversation), "post" do

      assert_select "input[name=?]", "conversation[name]"

      assert_select "input[name=?]", "conversation[shortname]"

      assert_select "textarea[name=?]", "conversation[description]"

      assert_select "textarea[name=?]", "conversation[front_template]"
    end
  end
end

require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  test "item attributes must not be empty" do
    item = Item.new
    assert item.invalid?
    assert item.errors[:item_type].any?
    assert item.errors[:media_type].any?
    assert item.errors[:posted_by].any?
  end
  
end

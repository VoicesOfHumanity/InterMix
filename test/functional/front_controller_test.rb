require 'test_helper'

class FrontControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  test "should get front page" do 
    get :index 
    assert_response :success
    assert_select 'title', 'Intermix'
  end
end

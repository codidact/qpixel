require 'test_helper'

class CloseReasonsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get close_reasons_index_url
    assert_response :success
  end

end

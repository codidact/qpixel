require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should create new comment" do
    sign_in users(:standard_user)
    post :create, :comment => { :post_id => answers(:two).id, :post_type => 'Answer', :content => "ABCDEF GHIJKL MNOPQR STUVWX YZ" }
    assert_not_nil assigns(:comment)
    assert_response(302)
  end
end

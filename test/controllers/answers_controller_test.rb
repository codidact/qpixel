require 'test_helper'

class AnswersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should convert to comment' do
    sign_in users(:moderator)

    pre_count = posts(:question_one).comments.count
    post :convert_to_comment, params: { id: posts(:answer_one).id, post_id: posts(:question_one).id }
    post_count = posts(:question_one).comments.count

    assert_response(:success)
    assert_not_nil assigns(:answer)
    assert_valid_json_response
    assert_equal pre_count + 1, post_count
    assert_equal true, assigns(:answer).deleted
  end

  test 'should 404 convert comment for non-moderator' do
    sign_in users(:editor)
    post :convert_to_comment, params: { id: posts(:answer_one).id, post_id: posts(:question_one).id }

    assert_response(:not_found)
  end
end

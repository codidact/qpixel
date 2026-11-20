require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should change category' do
    sign_in users(:deleter)

    post :change_category, params: { id: posts(:article_one).id, target_id: categories(:articles_only).id }

    assert_response(:success)
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:target)
    assert_valid_json_response
    assert_equal categories(:articles_only).id, assigns(:post).category_id
  end

  test 'should deny change category to unprivileged' do
    sign_in users(:standard_user)

    post :change_category, params: { id: posts(:article_one).id, target_id: categories(:articles_only).id }

    assert_response(:forbidden)
    assert_valid_json_response
    assert_equal ["You don't have permission to make that change.\n"], JSON.parse(response.body)['errors']
  end

  test 'should refuse to change category of wrong post type' do
    sign_in users(:deleter)

    post :change_category, params: { id: posts(:question_one).id, target_id: categories(:articles_only).id }

    assert_response(:conflict)
    assert_valid_json_response
    assert_equal ["This post type is not allowed in the #{categories(:articles_only).name} category.\n"],
                 JSON.parse(response.body)['errors']
  end
end

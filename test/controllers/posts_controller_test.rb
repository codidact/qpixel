require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should successfully get help center' do
    get :help_center
    assert_response 200
    assert_not_nil assigns(:posts)
  end

  test 'question permalink should correctly redirect' do
    get :share_q, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to question_path(posts(:question_one))
  end

  test 'answer permalink should correctly redirect' do
    get :share_a, params: { qid: posts(:question_one).id, id: posts(:answer_one).id }
    assert_response 302
    assert_redirected_to question_path(id: posts(:question_one).id, anchor: "answer-#{posts(:answer_one).id}")
  end

  test 'should change category' do
    sign_in users(:deleter)
    post :change_category, params: { id: posts(:article_one).id, target_id: categories(:articles_only).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:target)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal categories(:articles_only).id, assigns(:post).category_id
  end

  test 'should deny change category to unprivileged' do
    sign_in users(:standard_user)
    post :change_category, params: { id: posts(:article_one).id, target_id: categories(:articles_only).id }
    assert_response 403
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ["You don't have permission to make that change."], JSON.parse(response.body)['errors']
  end

  test 'should refuse to change category of wrong post type' do
    sign_in users(:deleter)
    post :change_category, params: { id: posts(:question_one).id, target_id: categories(:articles_only).id }
    assert_response 409
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ["This post type is not allowed in the #{categories(:articles_only).name} category."],
                 JSON.parse(response.body)['errors']
  end
end

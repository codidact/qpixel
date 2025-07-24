require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get new' do
    sign_in users(:moderator)
    get :new, params: { post_type: post_types(:help_doc).id }
    assert_nil flash[:danger]
    assert_response(:success)

    get :new, params: { post_type: post_types(:answer).id, parent: posts(:question_one).id }
    assert_nil flash[:danger]
    assert_response(:success)

    get :new, params: { post_type: post_types(:question).id, category: categories(:main).id }
    assert_nil flash[:danger]
    assert_response(:success)
  end

  test 'new requires authentication' do
    get :new, params: { post_type: post_types(:help_doc).id }
    assert_redirected_to_sign_in

    get :new, params: { post_type: post_types(:answer).id, parent: posts(:question_one).id }
    assert_redirected_to_sign_in

    get :new, params: { post_type: post_types(:question).id, category: categories(:main).id }
    assert_redirected_to_sign_in
  end

  test 'new rejects category post type without category' do
    sign_in users(:standard_user)
    get :new, params: { post_type: post_types(:question).id }
    assert_response(:found)
    assert_redirected_to root_path
    assert_not_nil flash[:danger]
  end

  test 'new rejects parented post type without parent' do
    sign_in users(:standard_user)
    get :new, params: { post_type: post_types(:answer).id }
    assert_response(:found)
    assert_redirected_to root_path
    assert_not_nil flash[:danger]
  end
end

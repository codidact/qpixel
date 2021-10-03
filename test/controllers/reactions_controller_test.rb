require 'test_helper'

class ReactionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationTestHelper

  test 'add should require sign in' do
    post :add, params: { reaction_id: reaction_types(:wfm).id, comment: nil, post_id: posts(:answer_two) }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'add should fail if no post id given' do
    sign_in users(:standard_user)
    assert_raise ActiveRecord::RecordNotFound do
      post :add, params: { reaction_id: reaction_types(:wfm).id, comment: nil }
    end
  end

  test 'add should fail if no reaction id given' do
    sign_in users(:standard_user)
    assert_raise ActiveRecord::RecordNotFound do
      post :add, params: { post_id: posts(:answer_two) }
    end
  end

  test 'add should work for standard users' do
    sign_in users(:standard_user)
    post :add, params: { reaction_id: reaction_types(:wfm).id, comment: nil, post_id: posts(:answer_two) }
    assert_not_nil assigns(:post)
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response 200
  end

  test 'add should fail if reaction type requires commment but none provided' do
    sign_in users(:standard_user)
    post :add, params: { reaction_id: reaction_types(:bad).id, comment: nil, post_id: posts(:answer_two) }
    assert_not_nil assigns(:post)
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_response 403
  end

  test 'add should pass if reaction type requires commment and one provided' do
    sign_in users(:standard_user)
    post :add, params: { reaction_id: reaction_types(:bad).id, comment: 'A' * 50, post_id: posts(:answer_two) }
    assert_not_nil assigns(:post)
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response 200
  end

  test 'add should pass if reaction type requires no commment but one provided' do
    sign_in users(:standard_user)
    post :add, params: { reaction_id: reaction_types(:old).id, comment: 'A' * 50, post_id: posts(:answer_two) }
    assert_not_nil assigns(:post)
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response 200
  end

  test 'add should allow adding second reaction of other type' do
    sign_in users(:standard_user)
    post :add, params: { reaction_id: reaction_types(:old).id, comment: nil, post_id: posts(:answer_one) }
    assert_not_nil assigns(:post)
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response 200
  end

  test 'add should prevent adding second reaction of same type' do
    sign_in users(:standard_user)
    post :add, params: { reaction_id: reaction_types(:wfm).id, comment: nil, post_id: posts(:answer_one) }
    assert_not_nil assigns(:post)
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_response 403
  end

  test 'add should fail if unprivileged user attempts to comment' do
    sign_in users(:standard_user)
    posts(:answer_two).update comments_disabled: true

    post :add, params: { reaction_id: reaction_types(:wfm).id, comment: 'A' * 50, post_id: posts(:answer_two) }
    assert_not_nil assigns(:post)
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_response 403

    posts(:answer_two).update comments_disabled: false
  end

  test 'add should pass if privileged user attempts to comment' do
    sign_in users(:admin)
    posts(:answer_two).update comments_disabled: true

    post :add, params: { reaction_id: reaction_types(:wfm).id, comment: 'A' * 50, post_id: posts(:answer_two) }
    assert_not_nil assigns(:post)
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response 200

    posts(:answer_two).update comments_disabled: false
  end

  test 'retract should require sign in' do
    post :retract, params: { reaction_id: reaction_types(:wfm).id, post_id: posts(:answer_two) }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'retract should fail if no post id given' do
    sign_in users(:standard_user)
    assert_raise ActiveRecord::RecordNotFound do
      post :retract, params: { reaction_id: reaction_types(:wfm).id }
    end
  end

  test 'retract should fail if no reaction id given' do
    sign_in users(:standard_user)
    assert_raise ActiveRecord::RecordNotFound do
      post :retract, params: { post_id: posts(:answer_two) }
    end
  end

  test 'retract should fail if no active reaction' do
    sign_in users(:standard_user)
    post :retract, params: { reaction_id: reaction_types(:wfm).id, post_id: posts(:answer_two) }
    assert_response 403
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'retract should pass if active reaction' do
    sign_in users(:standard_user)
    post :retract, params: { reaction_id: reaction_types(:wfm).id, post_id: posts(:answer_one) }
    assert_response 200
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'retract should fail if no active reaction of same type' do
    sign_in users(:standard_user)
    post :retract, params: { reaction_id: reaction_types(:bad).id, post_id: posts(:answer_one) }
    assert_response 403
    assert_equal 'failed', JSON.parse(response.body)['status']
  end
end

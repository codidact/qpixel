require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can feature post' do
    sign_in users(:moderator)
    before_audits = AuditLog.count
    post :feature, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:link).id
    assert_equal before_audits + 1, AuditLog.count, 'AuditLog not created on post feature'
  end

  test 'feature requires authentication' do
    post :feature, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'regular user cannot feature' do
    sign_in users(:deleter)
    post :feature, params: { id: posts(:question_one).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ['no_privilege'], JSON.parse(response.body)['errors']
  end
end

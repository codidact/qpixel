require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can feature post' do
    sign_in users(:moderator)
    before_audits = AuditLog.count
    try_feature posts(:question_one)

    assert_response(:success)
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:link).id
    assert_equal before_audits + 1, AuditLog.count, 'AuditLog not created on post feature'
  end

  test 'feature requires authentication' do
    try_feature posts(:question_one)

    assert_json_failure(:unauthorized)
    assert_json_response_field('error', I18n.t('users.errors.unauthorized'))
  end

  test 'regular user cannot feature' do
    sign_in users(:deleter)
    try_feature posts(:question_one)

    assert_json_failure(:not_found)
    assert_json_response_field('errors', ['not_found'])
  end

  def try_feature(target)
    post :feature, params: { id: target.id,
                             format: :json }
  end
end

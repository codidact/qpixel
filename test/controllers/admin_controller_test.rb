require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  PARAM_LESS_ACTIONS = [:index, :error_reports, :privileges, :audit_log, :email_query, :admin_email, :all_email].freeze

  test 'should get index' do
    sign_in users(:admin)
    get :index
    assert_response(:success)
  end

  test 'should deny anonymous users access' do
    sign_out :user
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(:not_found)
    end
  end

  test 'should deny standard users access' do
    sign_in users(:standard_user)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(:not_found)
    end
  end

  test 'should deny editors access' do
    sign_in users(:editor)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(:not_found)
    end
  end

  test 'should deny deleters access' do
    sign_in users(:deleter)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(:not_found)
    end
  end

  test 'should deny moderators access' do
    sign_in users(:moderator)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(:not_found)
    end
  end

  test 'should deny admins access to non-admin community' do
    RequestContext.community = Community.create(host: 'other.qpixel.com', name: 'Other')
    request.env['HTTP_HOST'] = 'other.qpixel.com'

    copy_abilities(RequestContext.community_id)

    sign_in users(:admin)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(:not_found)
    end
  end

  test 'should grant global admins access to non admin community' do
    RequestContext.community = Community.create(host: 'other.qpixel.com', name: 'Other')
    request.env['HTTP_HOST'] = 'other.qpixel.com'

    copy_abilities(RequestContext.community_id)

    sign_in users(:global_admin)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(:success)
    end
  end

  test 'should get single privilege' do
    sign_in users(:admin)
    get :show_privilege, params: { name: 'unrestricted', format: :json }

    assert_response(:success)
    assert_not_nil assigns(:ability)
    assert_valid_json_response
  end

  test 'should update privilege threshold' do
    sign_in users(:admin)
    post :update_privilege, params: { name: 'unrestricted', threshold: 0.6, type: 'post' }

    assert_response(:accepted)
    assert_not_nil assigns(:ability)
    assert_equal 0.6, assigns(:ability).post_score_threshold
    assert_valid_json_response
    assert_equal 'OK', JSON.parse(response.body)['status']
  end

  test 'should access error reports' do
    sign_in users(:admin)
    get :error_reports
    assert_response(:success)
    assert_not_nil assigns(:reports)
  end

  test 'should search error reports' do
    sign_in users(:admin)
    get :error_reports, params: { uuid: error_logs(:without_context).uuid }
    assert_response(:success)
    assert_not_nil assigns(:reports)
  end

  test 'should get audit log' do
    sign_in users(:admin)
    get :audit_log
    assert_response(:success)
    assert_not_nil assigns(:logs)
  end

  test 'should do email query' do
    sign_in users(:admin)
    post :do_email_query, params: { email: users(:standard_user).email }
    assert_response(:success)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:profiles)
  end

  test 'do_email_query should add a notice if the email does not exist' do
    sign_in users(:admin)
    post :do_email_query, params: { email: 'spock@vulcan.ufp' }
    assert_response(:success)
    assert_equal flash[:danger], I18n.t('admin.errors.email_query_not_found')
  end

  test 'send email methods should require auth' do
    [:send_admin_email, :send_all_email].each do |action|
      post action, params: { subject: 'test', body_markdown: 'test' }
      assert_response(:not_found)
    end
  end

  test 'send email methods should require global admin' do
    [:send_admin_email, :send_all_email].each do |action|
      sign_in users(:admin)
      post action, params: { subject: 'test', body_markdown: 'test' }
      assert_response(:not_found)
    end
  end

  test 'send email methods should work for global admins' do
    [:send_admin_email, :send_all_email].each do |action|
      sign_in users(:global_admin)
      post action, params: { subject: 'test', body_markdown: 'test' }
      assert_response(:found)
      assert_redirected_to admin_path
      assert_not_nil flash[:success]
    end
  end
end

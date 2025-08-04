require 'test_helper'

class CloseReasonsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index' do
    sign_in users(:admin)
    get :index
    assert_response(:success)
    assert_not_nil assigns(:close_reasons)
  end

  test 'should deny anonymous users access' do
    sign_out :user
    [:index, :new].each do |path|
      get path
      assert_response(:not_found)
    end
  end

  test 'should deny standard users access' do
    sign_in users(:standard_user)
    [:index, :new].each do |path|
      get path
      assert_response(:not_found)
    end
  end

  test 'should get new' do
    sign_in users(:global_admin)
    get :new
    assert_response(:success)
    assert_not_nil assigns(:close_reason)
  end

  test 'should correctly create close reasons' do
    sign_in users(:global_admin)

    [false, true].each do |global|
      try_create_close_reason(global: global, name: global ? 'all communities' : 'per-community')
      assert_response(:found)
      assert_redirected_to close_reasons_path(global: global ? '1' : nil)
      assert_not_nil assigns(:close_reason)&.id
    end
  end

  test 'should not create invalid close reasons' do
    sign_in users(:global_admin)
    try_create_close_reason(name: '')
    assert_response(:bad_request)
  end

  test 'should get edit' do
    sign_in users(:global_admin)
    get :edit, params: { id: close_reasons(:duplicate).id }
    assert_response(:success)
    assert_not_nil assigns(:close_reason)
  end

  test 'edit should fail for non-global admin on global reason' do
    sign_in users(:admin)
    get :edit, params: { id: close_reasons(:global).id }
    assert_response(:not_found)
  end

  test 'should update close reason' do
    sign_in users(:global_admin)

    try_update_close_reason(close_reasons(:duplicate), active: false)

    assert_response(:found)
    assert_redirected_to close_reasons_path
    assert_not_nil assigns(:close_reason)
    assert_equal false, assigns(:close_reason).active
  end

  test 'should not update close reasons to invalid states' do
    sign_in users(:global_admin)
    try_update_close_reason(close_reasons(:duplicate), name: '')
    assert_response(:bad_request)
  end

  private

  def try_create_close_reason(**opts)
    global = opts.delete(:global) || false

    post :create, params: { close_reason: { name: 'test',
                                            description: 'test',
                                            requires_other_post: true,
                                            active: true }.merge(opts),
                            global: global ? '1' : '0' }
  end

  def try_update_close_reason(reason, **opts)
    patch :update, params: { id: reason.id,
                             close_reason: opts }
  end
end

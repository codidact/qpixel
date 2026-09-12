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
    try_edit_close_reason close_reasons(:duplicate)
    assert_response(:success)
    assert_not_nil assigns(:close_reason)
  end

  test ':edit should fail for non-global admin on global reason' do
    sign_in users(:admin)
    try_edit_close_reason close_reasons(:global)
    assert_response(:not_found)
  end

  test ':edit should correctly scope non-global reasons for non-global admins' do
    sign_in users(:admin)
    try_edit_close_reason close_reasons(:second_community)
    assert_response(:not_found)
  end

  test ':update should correctly scope non-global reasons for non-global admins' do
    com = communities(:second)
    usr = users(:admin)

    sign_in usr

    close_reasons.select { |cr| cr.community&.id == com.id }.each do |reason|
      try_update_close_reason(reason,
                              active: false,
                              name: "#{reason.name} updated")

      assert_response(:not_found)
    end
  end

  test ':update should correctly change close reasons' do
    sign_in users(:global_admin)

    close_reasons.each do |reason|
      try_update_close_reason(reason, active: false, name: "#{reason.name} updated")

      assert_response(:found)
      assert_redirected_to close_reasons_path(global: reason.global? ? '1' : nil)

      @close_reason = assigns(:close_reason)

      assert_not_nil @close_reason
      assert_equal false, @close_reason.active
      assert_equal "#{reason.name} updated", @close_reason.name
    end
  end

  test ':update should not change close reasons to invalid states' do
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

  def try_edit_close_reason(reason)
    get :edit, params: { id: reason.id }
  end

  def try_update_close_reason(reason, **opts)
    patch :update, params: { id: reason.id,
                             close_reason: opts }
  end
end

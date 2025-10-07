require 'test_helper'

class ModWarningControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should require authentication to access pages' do
    sign_out :user
    [:log, :new].each do |path|
      get path, params: { user_id: users(:standard_user).id }
      assert_response(:not_found)
    end
  end

  test 'should require moderator status to access pages' do
    sign_in users(:standard_user)
    [:log, :new].each do |path|
      get path, params: { user_id: users(:standard_user).id }
      assert_response(:not_found)
    end
  end

  test 'mods or admins should be able to access pages' do
    [users(:moderator), users(:admin)].each do |user|
      sign_in(user)

      [:log, :new].each do |path|
        get path, params: { user_id: users(:standard_user).id }
        assert_response(:success)
      end
    end
  end

  test ':create should correctly create mod warnings' do
    user = users(:moderator)
    subject = users(:standard_user)

    sign_in(user)

    try_create_mod_warning(subject)

    assert_redirected_to(user_path(subject))
    warning = assigns(:warning)
    assert_not_nil warning
    assert_audit_log('warning_create', related: warning)
    assert_audit_log('suspension_create', related: warning)
  end

  test 'suspended user should redirect to current warning page' do
    sign_in users(:standard_user)
    mod_warnings(:first_warning).update(active: true)

    current_controller = @controller
    @controller = CategoriesController.new
    get :homepage
    @controller = current_controller

    assert_redirected_to '/warning'
    mod_warnings(:first_warning).update(active: false)
  end

  test 'warned user should be able to accept warning' do
    sign_in users(:standard_user)
    @warning = mod_warnings(:first_warning)
    @warning.update(active: true)
    post :approve, params: { approve_checkbox: true }
    @warning.reload
    assert_not @warning.active
  end

  test 'suspended user should not be able to accept pending suspension' do
    sign_in users(:standard_user)
    @warning = mod_warnings(:third_warning)
    @warning.update(active: true)
    post :approve, params: { approve_checkbox: true }
    @warning.reload
    assert @warning.active
  end

  test 'suspended user should be able to accept outdated suspension' do
    sign_in users(:standard_user)
    @warning = mod_warnings(:second_warning)
    @warning.update(active: true)
    post :approve, params: { approve_checkbox: true }
    @warning.reload
    assert_not @warning.active
  end

  test 'lift should correctly deactivate user suspensions' do
    sign_in users(:moderator)

    std = users(:standard_user)
    warning = mod_warnings(:third_warning)
    warning.update(active: true)

    try_lift_suspension(std)

    assert_response(:found)
    warning.reload
    assert_not warning.active
  end

  private

  # @param subject [User] to whom the mod warning is issued
  # @option opts :body [String]
  # @option opts :suspension_public_notice [String]
  # @option opts :is_suspension [Boolean]
  # @option opts :suspension_duration [Integer]
  def try_create_mod_warning(subject, **opts)
    post :create, params: {
      user_id: subject.id,
      mod_warning: {
        body: 'You have been suspended for science. Your sacrifice will not be forgotten',
        suspension_public_notice: 'Do not mind this suspension, nothing to see here, move along',
        is_suspension: true,
        suspension_duration: 365
      }.merge(opts)
    }
  end

  # @param subject [User] for whome to lift the suspension
  def try_lift_suspension(subject)
    post :lift, params: { user_id: subject.id }
  end
end

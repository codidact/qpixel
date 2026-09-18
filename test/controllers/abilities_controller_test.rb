require 'test_helper'

class AbilitiesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index when logged in' do
    sign_in users(:standard_user)
    get :index
    assert_response(:success)
    assert_not_nil assigns(:abilities)
    assert_not_nil assigns(:user)
  end

  test 'should get index when not logged in' do
    sign_out :user
    get :index
    assert_response(:success)
  end

  test 'should get index for other user when logged in' do
    sign_in users(:standard_user)
    get :index, params: { for: users(:closer).id }
    assert_response(:success)
    assert_not_nil assigns(:abilities)
    assert_not_nil assigns(:user)
  end

  test 'should get index for other user when not logged in' do
    sign_out :user
    get :index, params: { for: users(:closer).id }
    assert_response(:success)
    assert_not_nil assigns(:abilities)
    assert_not_nil assigns(:user)
  end

  test ':show should correctly handle auth requirement' do
    src_usr = users(:standard_user)
    tgt_usr = users(:closer)

    expected = [
      [{ auth: false, user: nil, for: nil }, true],
      [{ auth: false, user: nil, for: tgt_usr }, true],
      [{ auth: false, user: src_usr, for: nil }, true],
      [{ auth: false, user: src_usr, for: tgt_usr }, true],
      [{ auth: true, user: nil, for: nil }, true],
      [{ auth: true, user: nil, for: tgt_usr }, false],
      [{ auth: false, user: src_usr, for: nil }, true],
      [{ auth: false, user: src_usr, for: tgt_usr }, true]
    ]

    expected.each do |test_case|
      case_info = test_case.first
      case_src_usr = case_info[:user]
      case_tgt_usr = case_info[:for]

      is_allowed = test_case.second
      is_user_present = case_src_usr.present? || case_tgt_usr.present?

      SiteSetting['RequireSignInToViewUserAbilities'] = case_info[:auth]

      sign_in(case_src_usr) if case_src_usr.present?

      try_show_ability('unrestricted', case_tgt_usr)

      @ability = assigns(:ability)
      @user = assigns(:user)
      @your_ability = assigns(:your_ability)

      if is_allowed
        assert_response(:success)
        assert_nil_unless is_user_present, @user
        assert_nil_unless is_user_present, @your_ability
      else
        assert_redirected_to_sign_in
        assert_nil @ability
        assert_nil @user
        assert_nil @your_ability
      end

      sign_out(case_src_usr) if case_src_usr.present?
    end
  end

  test ':update should require authentication' do
    ability = abilities(:everyone)
    try_update_ability(ability, description: 'anonymous')
    assert_redirected_to_sign_in
  end

  test ':update should correctly update abilities' do
    ability = abilities(:everyone)

    users.each do |user|
      description = "#{user.name}'s edit"

      sign_in user
      try_update_ability(ability, description: description)

      if user.deleted? || user.community_user.deleted?
        assert_redirected_to_sign_in
      elsif user.can_edit_abilities?
        assert_redirected_to ability_url(id: ability.internal_id)
        assert_equal assigns(:ability).description, description
      else
        assert_response(:not_found)
      end
    end
  end

  test ':update should prevent invalid updates' do
    ability = abilities(:everyone)
    old_name = ability.name
    user = users(:global_admin)

    sign_in user

    [false, true].each do |network_push|
      try_update_ability(ability, description: 'valid',
                                  name: '',
                                  network_push: network_push)
      assert_response(:bad_request)

      ability.reload
      assert_equal ability.name, old_name
    end
  end

  test ':update should allow global mods & admins to network push' do
    ability = abilities(:everyone)

    users.select { |u| u.can_push_to_network?(ability) }.each do |user|
      description = "#{user.name}'s edit"

      sign_in user
      try_update_ability(ability, description: description, network_push: true)
      assert_redirected_to ability_url(id: ability.internal_id)

      network_abilities = Ability.unscoped.where(internal_id: ability.internal_id)
      assert network_abilities.any?

      network_abilities.each do |network_ability|
        assert_equal network_ability.description, description
      end
    end
  end

  private

  # @param internal_id [String] ID of the ability to show
  # @param user [User, nil] for whom to show the ability
  def try_show_ability(internal_id, user = nil)
    get :show, params: { id: internal_id,
                         for: user&.id }
  end

  # @param ability [Ability] ability to update
  def try_update_ability(ability, **opts)
    network_push = opts.delete(:network_push) || false

    patch :update, params: {
      ability: {}.merge(opts),
      id: ability.internal_id,
      network_push: network_push
    }
  end
end

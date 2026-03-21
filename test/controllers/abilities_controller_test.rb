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

  test 'should get show when logged in' do
    sign_in users(:standard_user)
    get :show, params: { id: 'unrestricted' }
    assert_response(:success)
    assert_not_nil assigns(:ability)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:your_ability)
  end

  test 'should get show when not logged in' do
    sign_out :user
    get :show, params: { id: 'unrestricted' }
    assert_response(:success)
  end

  test 'should get show for other user when logged in' do
    sign_in users(:standard_user)
    get :show, params: { id: 'unrestricted', for: users(:closer).id }
    assert_response(:success)
    assert_not_nil assigns(:ability)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:your_ability)
  end

  test 'should get show for other user when not logged in' do
    sign_out :user
    get :show, params: { id: 'unrestricted', for: users(:closer).id }
    assert_response(:success)
    assert_not_nil assigns(:ability)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:your_ability)
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

  private

  # @param ability [Ability] ability to update
  def try_update_ability(ability, **opts)
    patch :update, params: {
      ability: {}.merge(opts),
      id: ability.internal_id
    }
  end
end

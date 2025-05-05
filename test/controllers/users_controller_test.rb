require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationHelper

  test 'should get index' do
    get :index
    assert_not_nil assigns(:users)
    assert_response(200)
  end

  test 'should not include users not in current community' do
    @other_user = create_other_user
    get :index
    assert_not_includes assigns(:users), @other_user
    assert_response(200)
  end

  test 'should get show user page' do
    sign_in users(:standard_user)
    get :show, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_response(200)
  end

  test 'should get show user unauthenticated' do
    get :show, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_response 200
  end

  test 'should not show user page for non-community users' do
    @other_user = create_other_user
    sign_in users(:standard_user)
    get :show, params: { id: @other_user.id }
    assert_response(404)
  end

  test 'should get mod tools page' do
    sign_in users(:moderator)
    get :mod, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_response(200)
  end

  test 'should require authentication to access mod tools' do
    sign_out :user
    get :mod, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test 'should require moderator status to access mod tools' do
    sign_in users(:standard_user)
    get :mod, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test 'should destroy user' do
    sign_in users(:global_admin)
    delete :destroy, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test 'should require authentication to destroy user' do
    sign_out :user
    delete :destroy, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test 'should require moderator status to destroy user' do
    sign_in users(:standard_user)
    delete :destroy, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test 'should soft-delete user' do
    sign_in users(:global_admin)
    delete :soft_delete, params: { id: users(:standard_user).id, type: 'user' }
    assert_response 200
    assert_not_nil assigns(:user)
    assert_equal true, assigns(:user).deleted
  end

  test 'should require authentication to soft-delete user' do
    sign_out :user
    delete :soft_delete, params: { id: users(:standard_user).id, transfer: users(:editor).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test 'should require admin status to soft-delete user' do
    sign_in users(:standard_user)
    delete :soft_delete, params: { id: users(:standard_user).id, transfer: users(:editor).id }
    assert_nil assigns(:user)
    assert_response(404)
  end

  test 'should require authentication to get edit profile page' do
    get :edit_profile
    assert_response 302
  end

  test 'should get edit profile page' do
    sign_in users(:standard_user)
    get :edit_profile
    assert_response 200
  end

  test 'should redirect & show success notice on profile update' do
    sign_in users(:standard_user)
    patch :update_profile, params: { user: { username: 'std' } }
    assert_response 302
    assert_not_nil flash[:success]
    assert_not_nil assigns(:user)
    assert_equal users(:standard_user).id, assigns(:user).id
  end

  test 'should update profile text' do
    sign_in users(:standard_user)
    patch :update_profile, params: {
      user: { profile_markdown: 'ABCDEF GHIJKL' }
    }
    assert_equal assigns(:user).profile.strip, '<p>ABCDEF GHIJKL</p>'
  end

  test 'should update websites' do
    sign_in users(:standard_user)
    patch :update_profile, params: {
      user: { user_websites_attributes: {
        '0': { label: 'web', url: 'example.com' }
      } }
    }
    assert_not_nil assigns(:user).user_websites
    assert_equal 'web', assigns(:user).user_websites.first.label
    assert_equal 'example.com', assigns(:user).user_websites.first.url
  end

  test 'should update user discord link' do
    sign_in users(:standard_user)
    patch :update_profile, params: {
      user: { discord: 'example_user#1234' }
    }
    assert_equal 'example_user#1234', assigns(:user).discord
  end

  test 'should get full posts list for a user' do
    get :posts, params: { id: users(:standard_user).id }
    assert_response 200
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:posts)
  end

  test 'should get full posts list in JSON format' do
    get :posts, params: { id: users(:standard_user).id, format: 'json' }
    assert_response 200
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:posts)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
  end

  test 'should sort full posts lists correctly' do
    get :posts, params: { id: users(:standard_user).id, format: :json, sort: 'age' }
    assert_response 200
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:posts)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assigns(:posts).each_with_index do |post, idx|
      next if idx.zero?

      previous = assigns(:posts)[idx - 1]
      assert post.created_at <= previous.created_at,
             "@posts was expected in created_at DESC order, but got #{post.created_at.iso8601} before #{previous.created_at.iso8601}"
    end
  end

  test 'should require authentication to get mobile login' do
    get :qr_login_code
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should allow signed in users to get mobile login' do
    sign_in users(:standard_user)
    get :qr_login_code
    assert_response 200
    assert_not_nil assigns(:token)
    assert_not_nil assigns(:qr_code)
    assert_equal 1, User.where(login_token: assigns(:token)).count
    assert current_user.login_token_expires_at <= 5.minutes.from_now,
           'Login token expiry too long'
  end

  test 'should sign in user in response to valid mobile login request' do
    get :do_qr_login, params: { token: 'abcdefghijklmnopqrstuvwxyz01' }
    assert_response 302
    assert_equal 'You are now signed in.', flash[:success]
    assert_equal users(:closer).id, current_user.id
    assert_nil current_user.login_token
    assert_nil current_user.login_token_expires_at
  end

  test 'should refuse to sign in user using expired token' do
    get :do_qr_login, params: { token: 'abcdefghijklmnopqrstuvwxyz02' }
    assert_response 404
    assert_not_nil flash[:danger]
    assert_equal true, flash[:danger].start_with?("That login link isn't valid.")
    assert_nil current_user&.id
  end

  test 'should deny anonymous users access to annotations' do
    get :annotations, params: { id: users(:standard_user).id }
    assert_response 404
  end

  test 'should deny non-mods access to annotations' do
    sign_in users(:standard_user)
    get :annotations, params: { id: users(:standard_user).id }
    assert_response 404
  end

  test 'should get annotations' do
    sign_in users(:admin)
    get :annotations, params: { id: users(:standard_user).id }
    assert_response 200
    assert_not_nil assigns(:logs)
  end

  test 'should annotate user' do
    sign_in users(:admin)
    post :annotate, params: { id: users(:standard_user).id, comment: 'some words' }
    assert_response 302
    assert_redirected_to user_annotations_path(users(:standard_user))
  end

  test 'should deny access to deleted account' do
    get :show, params: { id: users(:deleted_account).id }
    assert_response 404
  end

  test 'should deny access to deleted profile' do
    get :show, params: { id: users(:deleted_profile).id }
    assert_response 404
    assert_not_nil assigns(:user)
  end

  test 'should allow moderator access to deleted account' do
    sign_in users(:moderator)
    get :show, params: { id: users(:deleted_account).id }
    assert_response 200
    assert_not_nil assigns(:user)
  end

  test 'should allow moderator access to deleted profile' do
    sign_in users(:moderator)
    get :show, params: { id: users(:deleted_profile).id }
    assert_response 200
    assert_not_nil assigns(:user)
  end

  # We can only test for one user per test block, hence there are
  # three test blocks of users with different permission models to
  # have a more unbiased check.

  test 'my vote summary redirects to current user summary (#1 deleter)' do
    sign_in users(:deleter)
    get :my_vote_summary
    assert_redirected_to vote_summary_path(users(:deleter))
    sign_out :user
  end

  test 'my vote summary redirects to current user summary (#2 std user)' do
    sign_in users(:standard_user)
    get :my_vote_summary
    assert_redirected_to vote_summary_path(users(:standard_user))
    sign_out :user
  end

  test 'my vote summary redirects to current user summary (#3 global_admin)' do
    sign_in users(:global_admin)
    get :my_vote_summary
    assert_redirected_to vote_summary_path(users(:global_admin))
    sign_out :user
  end

  test 'vote summary rendered for all users, signed in or out, own or others' do
    sign_out :user
    get :vote_summary, params: { id: users(:standard_user).id }
    assert_response 200

    get :vote_summary, params: { id: users(:closer).id }
    assert_response 200

    sign_in users(:editor)

    get :vote_summary, params: { id: users(:editor).id }
    assert_response 200

    get :vote_summary, params: { id: users(:deleter).id }
    assert_response 200
  end

  test 'me should redirect to currently signed in user' do
    std = users(:standard_user)

    sign_in std
    get :me, format: 'html'
    assert_redirected_to user_path(std)
  end

  test "me should return currently signed in user's data for JSON format" do
    mod = users(:moderator)

    sign_in mod
    get :me, format: 'json'
    assert_response 200

    data = JSON.parse(response.body)

    assert_equal data['id'], mod.id
    assert_equal data['username'], mod.username
  end

  private

  def create_other_user
    other_community = Community.create(host: 'other.qpixel.com', name: 'Other')
    RequestContext.redis.hset 'network/community_registrations', 'other@example.com', other_community.id
    other_user = User.create!(email: 'other@example.com', password: 'abcdefghijklmnopqrstuvwxyz', username: 'other_user')
    other_user.community_users.create!(community: other_community)
    other_user
  end
end

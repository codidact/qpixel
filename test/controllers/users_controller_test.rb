require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

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

  test 'soft deleting a user should not lose content' do
    sign_in users(:global_admin)
    assert_nothing_raised do
      relations = User.reflections
      pre_counts = relations.reject { |_, ref| ref.options[:dependent] == :destroy }
                            .map { |_, ref| [ref.klass, ref.klass.count] }.to_h

      id = users(:standard_user).id
      delete :soft_delete, params: { id: id, transfer: users(:editor).id }

      assert_response 200
      assert_not_nil assigns(:user)
      assert_equal 'success', JSON.parse(response.body)['status']

      # Make sure the record has actually been deleted.
      assert_raises ActiveRecord::RecordNotFound do
        User.find(id)
      end

      pre_counts.each do |model, count|
        # No content should have been lost to deleting the user, just re-assigned.
        # There should be one more AuditLog than before the operation, because deleting the user
        # should create one.
        if model.name == 'AuditLog'
          assert_equal count + 1, model.count, "Expected #{count} #{model.name.underscore.humanize.downcase.pluralize}, " \
                                               "got #{model.count}"
        else
          assert_equal count, model.count, "Expected #{count} #{model.name.underscore.humanize.downcase.pluralize}, " \
                                           "got #{model.count}"
        end
      end
    end
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

  test 'should update profile text' do
    sign_in users(:standard_user)
    patch :update_profile, params: { user: { profile_markdown: 'ABCDEF GHIJKL', website: 'https://example.com/user',
                                             twitter: '@standard_user' } }
    assert_response 302
    assert_not_nil flash[:success]
    assert_not_nil assigns(:user)
    assert_equal users(:standard_user).id, assigns(:user).id
    assert_not_nil assigns(:user).profile
    assert_equal 'standard_user', assigns(:user).twitter
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
    assert @controller.current_user.login_token_expires_at <= 5.minutes.from_now,
           'Login token expiry too long'
  end

  test 'should sign in user in response to valid mobile login request' do
    get :do_qr_login, params: { token: 'abcdefghijklmnopqrstuvwxyz01' }
    assert_response 302
    assert_equal 'You are now signed in.', flash[:success]
    assert_equal users(:closer).id, @controller.current_user.id
    assert_nil @controller.current_user.login_token
    assert_nil @controller.current_user.login_token_expires_at
  end

  test 'should refuse to sign in user using expired token' do
    get :do_qr_login, params: { token: 'abcdefghijklmnopqrstuvwxyz02' }
    assert_response 404
    assert_not_nil flash[:danger]
    assert_equal true, flash[:danger].start_with?("That login link isn't valid.")
    assert_nil @controller.current_user&.id
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

  private

  def create_other_user
    other_community = Community.create(host: 'other.qpixel.com', name: 'Other')
    other_user = User.create!(email: 'other@example.com', password: 'abcdefghijklmnopqrstuvwxyz', username: 'other_user')
    other_user.community_users.create!(community: other_community)
    other_user
  end
end

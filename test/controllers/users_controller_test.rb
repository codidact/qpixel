require 'test_helper'
require_relative 'concerns/users/users_abilities_test'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationHelper
  include UsersAbilitiesTest

  test 'should get index' do
    [:html, :json].each do |format|
      get :index, params: { format: format }

      assert_response(:success)

      case format
      when :html
        assert_not_nil(assigns(:users))
      when :json
        assert_valid_json_response
      end
    end
  end

  test 'should not include users not in current community' do
    @other_user = create_other_user
    get :index
    assert_not_includes assigns(:users), @other_user
    assert_response(:success)
  end

  test 'should get show user page' do
    sign_in users(:standard_user)
    get :show, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_response(:success)
  end

  test 'should get show user unauthenticated' do
    get :show, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_response(:success)
  end

  test 'should not show user page for non-community users' do
    @other_user = create_other_user
    sign_in users(:standard_user)
    get :show, params: { id: @other_user.id }
    assert_response(:not_found)
  end

  test 'should get mod tools page' do
    sign_in users(:moderator)
    get :mod, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_response(:success)
  end

  test 'should require authentication to access mod tools' do
    sign_out :user
    get :mod, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(:not_found)
  end

  test 'should require moderator status to access mod tools' do
    sign_in users(:standard_user)
    get :mod, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_response(:not_found)
  end

  test 'moderators and higher should be able to delete user profiles' do
    std_usr = users(:standard_user)

    users.select(&:at_least_moderator?).each do |user|
      sign_in(user)

      try_soft_delete_user('profile', std_usr)
      @user = assigns(:user)

      assert_response(:success)
      assert_not_nil @user
      assert @user.community_user.deleted
    end
  end

  test 'should soft-delete user' do
    sign_in users(:global_admin)

    try_soft_delete_user('user', users(:standard_user))

    assert_response(:success)
    assert_not_nil assigns(:user)
    assert assigns(:user).deleted
  end

  test 'only global moderators or admins should be able to soft-delete users' do
    std_usr = users(:standard_user)

    ([nil] + users).each do |user|
      if user.present?
        sign_in(user)
      end

      try_soft_delete_user('user', std_usr)

      if user&.at_least_global_moderator?
        assert_json_success
      elsif user&.at_least_moderator?
        assert_json_failure(:forbidden)
      else
        assert_json_failure(:not_found)
      end
    end
  end

  test 'should require authentication to soft-delete user' do
    sign_out :user

    try_soft_delete_user('user', users(:standard_user))

    assert_response(:not_found)
    assert_nil assigns(:user)
  end

  test 'should require admin status to soft-delete user' do
    sign_in users(:standard_user)

    try_soft_delete_user('user', users(:standard_user))

    assert_response(:not_found)
    assert_nil assigns(:user)
  end

  test 'should require authentication to get edit profile page' do
    get :edit_profile
    assert_response(:found)
  end

  test 'should get edit profile page' do
    sign_in users(:standard_user)
    get :edit_profile
    assert_response(:success)
  end

  test 'should redirect & show success notice on profile update' do
    sign_in users(:standard_user)
    patch :update_profile, params: { user: { username: 'std' } }

    assert_response(:found)
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

    assert_response(:success)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:posts)
  end

  test 'should get full posts list in JSON format' do
    get :posts, params: { id: users(:standard_user).id, format: 'json' }

    assert_response(:success)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:posts)
    assert_valid_json_response
  end

  test 'should sort full posts lists correctly' do
    get :posts, params: { id: users(:standard_user).id, format: :json, sort: 'age' }

    assert_response(:success)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:posts)
    assert_valid_json_response
    assigns(:posts).each_with_index do |post, idx|
      next if idx.zero?

      previous = assigns(:posts)[idx - 1]
      assert post.created_at <= previous.created_at,
             "@posts was expected in created_at DESC order, but got #{post.created_at.iso8601} before #{previous.created_at.iso8601}"
    end
  end

  test 'should require authentication to get mobile login' do
    get :qr_login_code
    assert_redirected_to_sign_in
  end

  test 'should allow signed in users to get mobile login' do
    sign_in users(:standard_user)
    get :qr_login_code

    assert_response(:success)
    assert_not_nil assigns(:token)
    assert_not_nil assigns(:qr_code)
    assert_equal 1, User.where(login_token: assigns(:token)).count
    assert current_user.login_token_expires_at <= 5.minutes.from_now,
           'Login token expiry too long'
  end

  test 'should sign in user in response to valid mobile login request' do
    get :do_qr_login, params: { token: 'abcdefghijklmnopqrstuvwxyz01' }

    assert_response(:found)
    assert_equal 'You are now signed in.', flash[:success]
    assert_equal users(:closer).id, current_user.id
    assert_nil current_user.login_token
    assert_nil current_user.login_token_expires_at
  end

  test 'should refuse to sign in user using expired token' do
    get :do_qr_login, params: { token: 'abcdefghijklmnopqrstuvwxyz02' }

    assert_response(:not_found)
    assert_not_nil flash[:danger]
    assert_equal true, flash[:danger].start_with?("That login link isn't valid.")
    assert_nil current_user&.id
  end

  test 'should deny anonymous users access to annotations' do
    get :annotations, params: { id: users(:standard_user).id }
    assert_response(:not_found)
  end

  test 'should deny non-mods access to annotations' do
    sign_in users(:standard_user)
    get :annotations, params: { id: users(:standard_user).id }
    assert_response(:not_found)
  end

  test 'should get annotations' do
    sign_in users(:admin)
    get :annotations, params: { id: users(:standard_user).id }
    assert_response(:success)
    assert_not_nil assigns(:logs)
  end

  test 'should annotate user' do
    sign_in users(:admin)
    post :annotate, params: { id: users(:standard_user).id, comment: 'some words' }
    assert_response(:found)
    assert_redirected_to user_annotations_path(users(:standard_user))
  end

  test 'should deny access to deleted account' do
    get :show, params: { id: users(:deleted_account).id }
    assert_response(:not_found)
  end

  test 'should deny access to deleted profile' do
    get :show, params: { id: users(:deleted_profile).id }
    assert_response(:not_found)
    assert_not_nil assigns(:user)
  end

  test 'should allow moderator access to deleted account' do
    sign_in users(:moderator)
    get :show, params: { id: users(:deleted_account).id }
    assert_response(:success)
    assert_not_nil assigns(:user)
  end

  test 'should allow moderator access to deleted profile' do
    sign_in users(:moderator)
    get :show, params: { id: users(:deleted_profile).id }
    assert_response(:success)
    assert_not_nil assigns(:user)
  end

  test 'my_vote_summary should redirect to the current user summary' do
    users.each do |user|
      sign_in user
      get :my_vote_summary

      if user.deleted? || user.community_user.deleted?
        assert_redirected_to_sign_in
      else
        assert_redirected_to vote_summary_path(user)
      end

      sign_out :user
    end
  end

  test 'vote summary rendered for all users, signed in or out, own or others' do
    sign_out :user
    get :vote_summary, params: { id: users(:standard_user).id }
    assert_response(:success)

    get :vote_summary, params: { id: users(:closer).id }
    assert_response(:success)

    sign_in users(:editor)

    get :vote_summary, params: { id: users(:editor).id }
    assert_response(:success)

    get :vote_summary, params: { id: users(:deleter).id }
    assert_response(:success)
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
    assert_response(:success)

    data = JSON.parse(response.body)

    assert_equal data['id'], mod.id
    assert_equal data['username'], mod.username
  end

  test 'role toggle should correctly grant & revoke moderator role' do
    sign_in users(:global_admin)

    mod = users(:moderator)

    post :role_toggle, params: { id: mod.id, role: 'mod' }
    assert_response(:success)

    mod.reload
    assert_equal mod.moderator?, false

    post :role_toggle, params: { id: mod.id, role: 'mod' }
    assert_response(:success)

    mod.reload
    assert_equal mod.moderator?, true
  end

  test 'role toggle should correctly grant & revoke admin role' do
    sign_in users(:global_admin)

    admin = users(:admin)

    post :role_toggle, params: { id: admin.id, role: 'admin' }
    assert_response(:success)

    admin.reload
    assert_equal admin.admin?, false

    post :role_toggle, params: { id: admin.id, role: 'admin' }
    assert_response(:success)

    admin.reload
    assert_equal admin.admin?, true
  end

  test 'role toggle should correctly grant & revoke global moderator role' do
    sign_in users(:global_admin)

    mod = users(:moderator)

    post :role_toggle, params: { id: mod.id, role: 'mod_global' }
    assert_response(:success)

    mod.reload
    assert_equal mod.global_moderator?, true

    post :role_toggle, params: { id: mod.id, role: 'mod_global' }
    assert_response(:success)

    mod.reload
    assert_equal mod.global_moderator?, false
  end

  test 'role toggle should correctly grant & revoke global admin role' do
    sign_in users(:global_admin)

    admin = users(:admin)

    post :role_toggle, params: { id: admin.id, role: 'admin_global' }
    assert_response(:success)

    admin.reload
    assert_equal admin.global_admin?, true

    post :role_toggle, params: { id: admin.id, role: 'admin_global' }
    assert_response(:success)

    admin.reload
    assert_equal admin.global_admin?, false
  end

  test 'full_log should only be accessible to mods or admins' do
    mod = users(:moderator)
    std = users(:standard_user)

    sign_in mod
    get :full_log, params: { id: std.id }
    assert_response(:success)

    sign_in std
    get :full_log, params: { id: std.id }
    assert_response(:not_found)
  end

  test 'activity should correctly apply single-type items filter' do
    std = users(:standard_user)

    sign_in std

    model_map = {
      'posts' => Post,
      'comments' => Comment,
      'edits' => SuggestedEdit
    }

    model_map.each do |filter, model|
      get :activity, params: { id: std.id, filter: filter }
      assert_response(:success)
      items = assigns(:items)

      assert(items.all? { |x| x.instance_of?(model) })
    end
  end

  test 'default activity filter should include items of all types' do
    std = users(:standard_user)

    sign_in std

    get :activity, params: { id: std.id }

    assert_response(:success)
    items = assigns(:items)

    edit_type = PostHistoryType.find_by(name: 'post_edited')

    [Post, Comment, SuggestedEdit, Flag, PostHistory, ModWarning].each do |model|
      assert(items.any? do |item|
               is_valid = if item.instance_of?(model)
                            case model
                            when Post
                              item.deleted == false
                            when Comment
                              item.comment_thread.deleted == false &&
                              item.deleted == false &&
                              item.post.deleted == false
                            when PostHistory
                              item.post_history_type == edit_type
                            when SuggestedEdit
                              item.post.deleted == false
                            end
                          else
                            true
                          end

               is_valid && item.user.same_as?(std)
             end)
    end
  end

  test 'full_log should correctly apply single-type items filter' do
    sign_in users(:moderator)

    model_map = {
      'posts' => Post,
      'comments' => Comment,
      'edits' => SuggestedEdit,
      'flags' => Flag,
      'warnings' => ModWarning
    }

    model_map.each do |filter, model|
      get :full_log, params: { id: users(:standard_user).id, filter: filter }
      assert_response(:success)
      items = assigns(:items)

      assert(items.all? { |x| x.instance_of?(model) })
    end
  end

  test 'full_log\'s \'interesting\' filter should include deleted comments' do
    sign_in users(:moderator)

    get :full_log, params: { id: users(:standard_user).id, filter: 'interesting' }
    assert_response(:success)
    items = assigns(:items)

    deleted_comment = comments(:deleted)

    assert(items.any? { |x| x.instance_of?(Comment) && x.id == deleted_comment.id })
  end

  test 'full_log\'s \'interesting\' filter should include declined flags' do
    sign_in users(:moderator)

    get :full_log, params: { id: users(:standard_user).id, filter: 'interesting' }
    assert_response(:success)
    items = assigns(:items)

    declined_flag = flags(:declined)

    assert(items.any? { |x| x.instance_of?(Flag) && x.id == declined_flag.id })
  end

  test 'set_filter should correctly save valid filters' do
    sign_in users(:standard_user)

    [false, true].each do |is_default|
      try_save_filter(is_default: is_default)
      assert_json_success
    end
  end

  test 'set_preference should correclty save valid preferences' do
    sign_in users(:standard_user)

    pref_key = 'default_license'
    license = licenses(:cc_by_sa)

    [nil, communities(:sample)].each do |community|
      try_save_preference(pref_key, license, community: community)

      assert_response(:success)
      assert_valid_json_response

      parsed_body = JSON.parse(response.body)
      assert_equal 'success', parsed_body['status']
      assert_not_nil parsed_body['preferences']

      comm_key = community.present? ? 'community' : 'global'
      assert_not_nil parsed_body['preferences'][comm_key]
      assert_equal license.id.to_s, parsed_body['preferences'][comm_key][pref_key]
    end
  end

  test 'set_preference should correctly handle invalid preferences' do
    sign_in users(:standard_user)

    [nil, communities(:sample)].each do |community|
      post :set_preference, params: { community: community, format: :json }

      assert_response(:bad_request)
      assert_valid_json_response

      parsed_body = JSON.parse(response.body)
      assert_equal 'failed', parsed_body['status']
      assert_not_nil parsed_body['message']
    end
  end

  test 'default_filter should correctly respond to missing category' do
    sign_in users(:standard_user)
    try_default_filter(nil)
    assert_response(:bad_request)
  end

  test 'default_filter should correctly get default category filters' do
    sign_in users(:standard_user)
    try_default_filter(categories(:main))
    assert_json_success
  end

  test 'HTML filters should redirect to sign in for anonymous users' do
    try_filters(format: :html)
    assert_redirected_to_sign_in
  end

  test 'JSON filters should return system filters for anonymous users' do
    try_filters(format: :json)

    assert_response(:success)
    assert_valid_json_response

    parsed = JSON.parse(response.body)
    assert parsed.any?
    parsed.each do |name, filter|
      assert filter['system'], "'#{name}' is not a system filter"
    end
  end

  private

  def create_other_user
    other_community = Community.create(host: 'other.qpixel.com', name: 'Other')
    RequestContext.redis.hset('network/community_registrations', 'other@example.com', other_community.id)
    other_user = User.create!(email: 'other@example.com', password: 'abcdefghijklmnopqrstuvwxyz', username: 'other_user')
    other_user.community_users.create!(community: other_community)
    other_user
  end

  def try_filters(format: :json)
    get :filters, params: { format: format }
  end

  def try_default_filter(category)
    get :default_filter, params: {
      category: category&.id,
      format: :json
    }
  end

  def try_save_filter(**opts)
    filter = { name: 'test filter' }.merge(opts)
    post :set_filter, params: filter.merge({ format: :json })
  end

  # @param type [String] deletion type (user or profile)
  # @param user [User] user to soft delete
  def try_soft_delete_user(type, user)
    delete :soft_delete, params: { id: user.id,
                                   type: type,
                                   format: :json }
  end

  def try_save_preference(name, value, community: nil)
    post :set_preference, params: {
      community: community,
      name: name,
      value: value,
      format: :json
    }
  end
end

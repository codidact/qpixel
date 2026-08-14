module UserModToolsTest
  extend ActiveSupport::Concern

  included do
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

        assert(items.all?(model))
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

    test 'should spam-block spammer on deletion' do
      sign_in users(:global_admin)
      spammer = users(:spammer)

      try_soft_delete_user('user', spammer)

      blocked_item = BlockedItem.where(item_type: 'email', value: spammer.email)
      assert blocked_item.any?,
             "Expected a BlockedItem for #{spammer.email} but none was found."
    end

    test 'should not spam-block high-rep user on deletion' do
      sign_in users(:global_admin)
      high_rep_spammer = users(:high_rep_spammer)

      try_soft_delete_user('user', high_rep_spammer)

      blocked_item = BlockedItem.where(item_type: 'email', value: high_rep_spammer.email)
      assert_not blocked_item.any?,
                 "Expected no BlockedItem for #{high_rep_spammer.email} but one was found."
    end
  end
end
module UsersAbilitiesTest
  test 'mod_privilege_action: grant as new' do
    sign_in users(:moderator)
    post :mod_privilege_action, params: { ability: abilities(:flag_curate).internal_id, do: 'grant',
                                          id: users(:standard).id }
    assert_response(:success)
    assert users(:standard_user).community_user.ability?(abilities(:flag_curate).internal_id),
           "User was not granted expected ability #{abilities(:flag_curate).internal_id}"
  end

  test 'mod_privilege_action: grant as unsuspend' do
    sign_in users(:moderator)
    post :mod_privilege_action, params: { ability: abilities(:edit_posts).internal_id, do: 'grant',
                                          id: users(:enabled_2fa).id }
    assert_response(:success)
    assert users(:enabled_2fa).community_user.ability?(abilities(:edit_posts).internal_id),
           "User was not granted expected ability #{abilities(:edit_posts).internal_id}"
  end

  test 'mod_privilege_action: suspend' do
    sign_in users(:moderator)
    post :mod_privilege_action, params: { ability: abilities(:unrestricted).internal_id, do: 'suspend',
                                          id: users(:standard_user).id }
    assert_response(:success)
    assert_not users(:standard_user).community_user.ability?(abilities(:unrestricted).internal_id),
               "User still has ability #{abilities(:unrestricted).internal_id} that should have been suspended"
  end

  test 'mod_privilege_action: delete' do
    sign_in users(:moderator)
    post :mod_privilege_action, params: { ability: abilities(:unrestricted).internal_id, do: 'delete',
                                          id: users(:standard_user).id }
    assert_response(:success)
    assert_not users(:standard_user).community_user.ability?(abilities(:unrestricted).internal_id),
               "User still has ability #{abilities(:unrestricted).internal_id} that should have been deleted"
  end

  test 'mod_privilege_action: unrecognized action' do
    sign_in users(:moderator)
    post :mod_privilege_action, params: { ability: abilities(:unrestricted).internal_id, do: 'unrecognized',
                                          id: users(:standard_user).id }
    assert_response(:not_found)
  end

  test 'mod_privilege_action: require moderator' do
    post :mod_privilege_action, params: { ability: abilities(:unrestricted).internal_id, do: 'unrecognized',
                                          id: users(:standard_user).id }
    assert_response(:not_found)
  end
end

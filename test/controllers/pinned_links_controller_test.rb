require 'test_helper'

class PinnedLinksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::ControllerHelpers

  test 'edit should require moderator' do
    sign_in users(:standard_user)
    get :edit, params: { id: pinned_links(:active_with_label).id }
    assert_response(:not_found)
  end

  test 'edit should work for moderators' do
    sign_in users(:moderator)
    get :edit, params: { id: pinned_links(:active_with_label).id }
    assert_response(:success)
    assert_not_nil assigns(:link)
  end

  test 'update should require moderator' do
    sign_in users(:standard_user)
    post :update, params: { id: pinned_links(:active_with_label).id, pinned_link: { label: 'updated label' } }
    assert_response(:not_found)
  end

  test 'update should work for moderators' do
    sign_in users(:moderator)
    post :update, params: { id: pinned_links(:active_with_label).id, pinned_link: { label: 'updated label' } }
    assert_response(:found)
    assert_redirected_to pinned_links_path
    assert_not_nil assigns(:link)
    assert_equal 'updated label', assigns(:link).label
  end
end

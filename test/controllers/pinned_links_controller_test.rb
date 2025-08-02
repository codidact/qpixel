require 'test_helper'

class PinnedLinksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'only mods or higher should be able to create pinned links' do
    post = posts(:question_one)

    users.each do |user|
      sign_in user
      try_create_pinned_link(post: post)
      assert_response(user.at_least_moderator? ? :found : :not_found)
    end
  end

  test 'only mods or higher should be able to edit pinned links' do
    link = pinned_links(:active_with_label)

    users.each do |user|
      sign_in user
      try_edit_pinned_link(link)
      assert_response(user.at_least_moderator? ? :success : :not_found)
    end
  end

  test 'only mods or higher should be able to update pinned links' do
    link = pinned_links(:active_with_label)

    users.each do |user|
      sign_in user
      try_update_pinned_link(link, label: 'updated label')
      assert_response(user.at_least_moderator? ? :found : :not_found)
    end
  end

  test 'create should correctly create pinned links' do
    sign_in users(:moderator)

    try_create_pinned_link(post: posts(:question_one))

    assert_response(:found)
    assert_redirected_to pinned_links_path
    assert_not_nil assigns(:link)
  end

  test 'update should correctly update pinned links' do
    sign_in users(:moderator)

    try_update_pinned_link(pinned_links(:active_with_label), label: 'updated label')

    assert_response(:found)
    assert_redirected_to pinned_links_path
    assert_not_nil assigns(:link)
    assert_equal 'updated label', assigns(:link).label
  end

  private

  def try_create_pinned_link(**opts)
    community_id = opts.delete(:community)&.id
    post_id = opts.delete(:post)&.id

    post :create, params: {
      pinned_link: {
        community_id: community_id,
        post_id: post_id
      }.merge(opts)
    }
  end

  def try_edit_pinned_link(link)
    get :edit, params: { id: link.id }
  end

  def try_update_pinned_link(link, **opts)
    post :update, params: {
      id: link.id,
      pinned_link: opts
    }
  end
end

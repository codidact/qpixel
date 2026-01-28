require 'test_helper'

class PinnedLinksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test ':index should correctly filter by community' do
    sign_in users(:global_moderator)

    get :index, params: { global: '1' }
    @links = assigns(:links)

    assert_response(:success)
    assert @links.any?
    assert @links.none?(&:community_id?)

    get :index, params: { global: '2' }
    @links = assigns(:links)

    assert_response(:success)
    assert @links.any?

    links_ids = pinned_links.map(&:id)

    assert(@links.all? { |link| links_ids.include?(link.id) })
  end

  test ':index should correctly filter by activity status' do
    sign_in users(:moderator)

    get :index, params: { filter: 'all' }
    assert_response(:success)
    assert assigns(:links).any?

    get :index, params: { filter: 'inactive' }
    @links = assigns(:links)

    assert_response(:success)
    assert @links.any?
    assert @links.none?(&:active?)
  end

  test ':index should correctly filter by period' do
    sign_in users(:moderator)

    now = DateTime.now

    get :index
    @links = assigns(:links)
    assert_response(:success)
    assert @links.any?

    links_ids = pinned_links.map(&:id)
    assert(@links.all? { |link| links_ids.include?(link.id) })

    get :index, params: { period: 'past' }
    @links = assigns(:links)
    assert_response(:success)
    assert @links.any?

    @links.each do |link|
      assert link.timed? && link.shown_before < now
    end

    get :index, params: { period: 'current' }
    @links = assigns(:links)
    assert_response(:success)
    assert @links.any?

    @links.each do |link|
      assert !link.timed? || (link.shown_before > now && link.shown_after <= now)
    end

    get :index, params: { period: 'future' }
    @links = assigns(:links)
    assert_response(:success)
    assert @links.any?

    @links.each do |link|
      assert link.timed? && link.shown_before > now && link.shown_after > now
    end
  end

  test ':index should treat invalid period filter as no filter' do
    sign_in users(:moderator)

    get :index, params: { period: 'invalid' }
    @links = assigns(:links)
    assert_response(:success)

    links_ids = pinned_links.map(&:id)
    assert(@links.all? { |link| links_ids.include?(link.id) })
  end

  test 'only mods or higher should be able to see pinned links' do
    users.each do |user|
      sign_in user
      get :index

      assert_response(user.at_least_moderator? ? :success : :not_found)
    end
  end

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

  test 'create should correctly handle invalid pinned links' do
    sign_in users(:moderator)
    try_create_pinned_link
    assert_response(:bad_request)
    assert assigns(:link)&.errors&.any?
  end

  test 'update should correctly update pinned links' do
    sign_in users(:moderator)

    try_update_pinned_link(pinned_links(:active_with_label), label: 'updated label')

    assert_response(:found)
    assert_redirected_to pinned_links_path
    assert_not_nil assigns(:link)
    assert_equal 'updated label', assigns(:link).label
  end

  test 'update should correctly handle invalid pinned links' do
    sign_in users(:moderator)
    try_update_pinned_link(pinned_links(:active_with_label), link: nil)
    assert_response(:bad_request)
    assert assigns(:link)&.errors&.any?
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

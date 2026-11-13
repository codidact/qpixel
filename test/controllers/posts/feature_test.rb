require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test ':feature should correctly feature a given post' do
    user = users(:moderator)
    post = posts(:without_pinned_links)

    sign_in(user)
    @request.set_header('HTTP_REFERER', post_path(post))

    [:html, :json].each do |format|
      PinnedLink.where(post: post).update_all(active: false)

      try_feature post, format: format
      @link = assigns(:link)
      @post = assigns(:post)
      assert_not_nil(@link)
      assert_not_nil(@post)
      assert_audit_log('pinned_link_create', related: @link)

      case format
      when :html
        assert_equal I18n.t('posts.success.feature'), flash[:success]
        assert_redirected_to(post_path(@post))
      when :json
        assert_json_success
      end
    end
  end

  test ':feature should require the user to be at least a moderator' do
    post = posts(:without_pinned_links)

    users.each do |user|
      sign_in(user)

      [:html, :json].each do |format|
        PinnedLink.where(post: post).update_all(active: false)

        try_feature post, format: format
        assert_equal user.at_least_moderator?, post.featured?,
                     "Unexpected outcome for user '#{user}'"

        next if user.at_least_moderator? || user.deleted? || user.community_user.deleted?

        case format
        when :html
          assert_response(:not_found)
        when :json
          assert_json_failure(:not_found)
          assert_json_response_field('errors', ['not_found'])
        end
      end

      sign_out :user
    end
  end

  test ':feature should only allow unfeatured posts to be featured' do
    user = users(:moderator)
    post = posts(:without_pinned_links)

    sign_in(user)
    @request.set_header('HTTP_REFERER', post_path(post))

    try_feature post, format: :json
    assert_json_success

    [:html, :json].each do |format|
      try_feature post, format: format

      error_message = I18n.t('posts.errors.feature_conflict')

      case format
      when :html
        assert_equal error_message, flash[:danger]
        assert_redirected_to(post_path(post))
      when :json
        assert_json_failure(:conflict)
        assert_json_response_field('message', error_message)
      end
    end
  end

  test ':feature should require authentication' do
    post = posts(:without_pinned_links)

    [:html, :json].each do |format|
      try_feature post, format: format

      error_message = I18n.t('users.errors.unauthorized')

      case format
      when :html
        assert_equal error_message, flash[:error]
        assert_redirected_to_sign_in
      when :json
        assert_json_failure(:unauthorized)
        assert_json_response_field('error', error_message)
      end
    end
  end

  private

  # @param target [Post] post to feature
  def try_feature(target, format: :html)
    post :feature, params: { id: target.id, format: format }
  end
end

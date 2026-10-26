require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test ':unfeature should correctly unfeature a given post' do
    user = users(:moderator)
    post = posts(:question_one)
    link = pinned_links(:active_with_post)

    sign_in user
    @request.set_header('HTTP_REFERER', post_path(post))

    [:html, :json].each do |format|
      PinnedLink.where(post: post).update_all(active: true)

      try_unfeature post, format: format
      @post = assigns(:post)
      assert_not_nil(@post)
      assert_audit_log('pinned_link_update', related: link)

      case format
      when :html
        assert_equal I18n.t('posts.success.unfeature'), flash[:success]
        assert_redirected_to(post_path(@post))
      when :json
        assert_json_success
      end
    end
  end

  test ':unfeature should require the user to be at least a moderator' do
    post = posts(:question_one)

    users.each do |user|
      sign_in(user)

      [:html, :json].each do |format|
        PinnedLink.where(post: post).update_all(active: true)

        try_unfeature post, format: format
        assert_not_equal user.at_least_moderator?, post.featured?,
                         "Unexpected outcome for user '#{user.name}'"

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

  test ':unfeature should require authentication' do
    post = posts(:question_one)

    [:html, :json].each do |format|
      try_unfeature post, format: format

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

  test ':unfeature should correctly handle update failures' do
    post = posts(:question_one)
    link = pinned_links(:active_with_post)
    user = users(:global_admin)

    sign_in user
    @request.set_header('HTTP_REFERER', post_path(post))

    link.stub(:update, false) do
      PinnedLink.stub_any_instance(:update, false) do
        [:html, :json].each do |format|
          try_unfeature post, format: format

          error_message = I18n.t('posts.errors.unfeature_generic')

          case format
          when :html
            assert_equal error_message, flash[:danger]
            assert_redirected_to(post_path(post))
          when :json
            assert_json_failure(:internal_server_error)
            assert_json_response_field('message', error_message)
          end
        end
      end
    end
  end

  private

  # @param target [Post] post to unfeature
  def try_unfeature(target, format: :html)
    delete :unfeature, params: { id: target.id,
                                 format: format }
  end
end

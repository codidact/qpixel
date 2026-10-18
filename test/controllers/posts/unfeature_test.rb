require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test ':unfeature should require the user to be at least a moderator' do
    post = posts(:question_one)
    link = pinned_links(:active_with_post)

    users.each do |user|
      PinnedLink.where(post: post).update_all(active: true)
      sign_in(user)

      try_unfeature(post)
      assert_not_equal user.at_least_moderator?, post.featured?, "Unexpected outcome for user '#{user.name}'"

      if user.at_least_moderator?
        assert_audit_log('pinned_link_update', related: link)
      end

      sign_out :user
    end
  end

  test ':unfeature should require authentication' do
    try_unfeature posts(:question_one)
    assert_json_failure(:unauthorized)
    assert_json_response_field('error', I18n.t('users.errors.unauthorized'))
  end

  # @param target [Post] post to unfeature
  def try_unfeature(target)
    delete :unfeature, params: { id: target.id,
                               format: :json }
  end
end

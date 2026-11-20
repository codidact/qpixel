require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'any non-deleted user with a profile should be able to follow threads' do
    thread = comment_threads(:normal)

    users.each do |user|
      next unless user.profile_on?(RequestContext.community)
      next if user.deleted? || user.community_user.deleted?

      sign_in user
      try_follow_thread(thread)

      assert_response(:success, user.community_user.inspect)
      assert_valid_json_response
      assert_equal 'success', JSON.parse(response.body)['status']
    end
  end
end

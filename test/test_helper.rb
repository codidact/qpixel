require 'simplecov'
require 'simplecov_json_formatter'
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start('rails')

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'minitest/ci'
Minitest::Ci.report_dir = Rails.root.join('test/reports/minitest').to_s

# cleanup seeds after all tests are run (can't use teardown callbacks as they run after each test)
Minitest.after_run do
  # IMPORTANT: the order is very specific to prevent FK constraint errors without disabling them
  models = [
    WarningTemplate,
    ModWarning,
    ThreadFollower,
    Comment,
    CommentThread,
    Reaction,
    ReactionType,
    Flag,
    PinnedLink,
    PostFlagType,
    SuggestedEdit,
    Vote,
    Post,
    PostHistory,
    PostHistoryTag,
    PostHistoryType,
    UserAbility,
    AbilityQueue,
    Ability,
    CategoryFilterDefault,
    Category,
    CloseReason,
    PostType,
    License,
    TagSynonym,
    Tag,
    TagSet,
    Filter,
    CommunityUser,
    UserWebsite,
    AuditLog,
    BlockedItem,
    EmailLog,
    ErrorLog,
    Subscription,
    User,
    Notification,
    SiteSetting,
    Community
  ]

  models.each do |model|
    if model == PostType
      model.unscoped.where.not(answer_type_id: nil).delete_all
      model.unscoped.where(answer_type_id: nil).delete_all
    elsif model == Tag
      model.unscoped.where.not(parent_id: nil).delete_all
      model.unscoped.where(parent_id: nil).delete_all
    elsif model == User
      model.unscoped.where.not(deleted_by_id: nil).delete_all
      model.unscoped.where(deleted_by_id: nil).delete_all
    else
      model.unscoped.all.delete_all
    end
  end
end

Dir.glob(Rails.root.join('test/support/**/*.rb')).sort.each { |f| require f }

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  setup :set_request_context

  teardown :clear_cache

  protected

  # Overrides minitest' load_fixtures method to also load our seeds when fixtures are loaded.
  # This means that we can leverage it's smart transaction behavior to significantly speed up our tests (by a factor of 6).
  def load_fixtures(config)
    # Loading a fixture deletes all data in the same tables, so it has to happen before we load our normal seeds.
    fixture_data = super(config)
    load_tags_paths
    load_seeds

    # We do need to return the same thing as the original method to not break fixtures
    fixture_data
  end

  # Ensures that a community is set for all requests that will be made (on this thread)
  def set_request_context
    comm = Community.first || Community.create(name: 'Test', host: 'test.host')
    RequestContext.community = comm
  end

  def load_seeds
    set_request_context
    Rails.application.load_seed
  end

  def load_tags_paths
    sql = File.read(Rails.root.join('db/scripts/create_tags_path_view.sql'))
    ActiveRecord::Base.connection.execute(sql)
  end

  def clear_cache
    Rails.cache.clear
  end

  def copy_abilities(community_id)
    Ability.unscoped.where(community: Community.first).each do |a|
      Ability.create(a.attributes.merge(community_id: community_id, id: nil))
    end
  end

  def assert_valid_json_response
    assert_nothing_raised do
      JSON.parse(response.body)
    end
  end

  def assert_json_response_message(expected)
    assert_equal expected, JSON.parse(response.body)['message']
  end

  def assert_redirected_to_sign_in
    assert_response(:found)
    assert_redirected_to(new_user_session_path)
  end

  PostMock = Struct.new(:title, :body_markdown, :body, :tags_cache, :edit, keyword_init: true)

  def sample
    PostMock.new(
      title: 'This is a sample title',
      body_markdown: 'This is a sample post with some **Markdown** and [a link](/).',
      body: '<p>This is a sample post with some <b>Markdown</b> and <a href="/">a link</a></p>',
      tags_cache: ['discussion', 'posts', 'tags'],
      edit: PostMock.new(
        title: 'This is another sample title',
        body_markdown: 'This is a sample post with some more **Markdown** and [a link](/).',
        body: '<p>This is a sample post with some more <b>Markdown</b> and <a href="/">a link</a></p>',
        tags_cache: ['discussion', 'posts', 'tags', 'edits'],
        edit: nil
      )
    )
  end
end

class ActionController::TestCase
  setup :load_host

  def load_host
    request.env['HTTP_HOST'] = Community.first.host
  end
end

class ActionDispatch::IntegrationTest
  setup :load_host

  def load_host
    integration_session.host = Community.first.host
  end
end

module CommentsControllerHelper
  extend ActiveSupport::Concern

  private

  # Attempts to archive a given comment thread
  # @param thread [CommentThread] thread to archive
  def try_archive_thread(thread)
    post :thread_restrict, params: { id: thread.id, type: 'archive' }
  end

  # Attempts to create a comment thread on a given post
  # @param post [Post] post to create the thread on
  # @param mentions [Array<User>] list of user @-mentions, if any
  # @param content [String] content of the initial thread comment
  # @param title [String] title of the thread, if any
  def try_create_thread(post,
                        mentions: [],
                        content: 'sample comment content',
                        title: 'sample thread title',
                        format: :html)
    body_parts = [content] + mentions.map { |u| "@##{u.id}" }

    post(:create_thread, params: { post_id: post.id,
                                   title: title,
                                   body: body_parts.join(' ') },
                                   format: format)
  end

  # Attempts to create a comment in a given thread
  # @param thread [CommentThread] thread to create the comment in
  # @param mentions [Array<User>] list of user @-mentions, if any
  # @param content [String] content of the comment, if any
  def try_create_comment(thread,
                         mentions: [],
                         content: 'sample comment content',
                         format: :html)
    content_parts = [content] + mentions.map { |u| "@##{u.id}" }

    post(:create, params: { id: thread.id,
                            post_id: thread.post.id,
                            content: content_parts.join(' ') },
                            format: format)
  end

  # Attempts to delete a given comment thread
  # @param thread [CommentThread] thread to delete
  def try_delete_thread(thread)
    post :thread_restrict, params: { id: thread.id, type: 'delete' }
  end

  # Attempts to undelete a given comment thread
  # @param thread [CommentThread] thread to undelete
  def try_undelete_thread(thread)
    post :thread_unrestrict, params: { id: thread.id, type: 'delete' }
  end

  # Attempts to follow a given comment thread
  # @param thread [CommentThread] thread to follow
  def try_follow_thread(thread)
    post :thread_restrict, params: { id: thread.id, type: 'follow' }
  end

  # Attempts to unfollow a given comment thread
  # @param thread [CommentThread] thread to unfollow
  def try_unfollow_thread(thread)
    post :thread_unrestrict, params: { id: thread.id, type: 'follow' }
  end

  # Attempts to lock a given comment thread
  # @param thread [CommentThread] thread to lock
  # @param duration [Integer] lock duration, in days
  def try_lock_thread(thread, duration: nil)
    post :thread_restrict, params: { duration: duration, id: thread.id, type: 'lock' }
  end

  # Attempts to unlock a given comment thread
  # @param thread [CommentThread] thread to unlock
  def try_unlock_thread(thread)
    post :thread_unrestrict, params: { id: thread.id, type: 'lock' }
  end

  # Attempts to rename a given comment thread
  # @param thread [CommentThread] thread to rename
  # @param title [String] new thread title, if any
  def try_rename_thread(thread, title: 'new thread title')
    post :thread_rename, params: { id: thread.id, title: title }
  end

  # Attempts to show a single comment
  # @param comment [Comment] comment to show
  def try_show_comment(comment, format: :html)
    get :show, params: { id: comment.id, format: format }
  end

  # Attempts to update a given comment
  # @param comment [Comment] comment to update
  # @param content [String] new content of the comment, if any
  def try_update_comment(comment, content: 'Edited comment content')
    post :update, params: { id: comment.id, comment: { content: content } }
  end
end

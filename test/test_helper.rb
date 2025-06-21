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

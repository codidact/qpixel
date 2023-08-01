require 'coveralls'
Coveralls.wear!('rails')

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'minitest/ci'
Minitest::Ci.report_dir = Rails.root.join('test/reports/minitest').to_s

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

  def clear_cache
    Rails.cache.clear
  end

  def copy_abilities(community_id)
    Ability.unscoped.where(community: Community.first).each do |a|
      Ability.create(a.attributes.merge(community_id: community_id, id: nil))
    end
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

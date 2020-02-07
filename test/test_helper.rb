require 'coveralls'
Coveralls.wear!('rails')

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'minitest/ci'
Minitest::Ci.report_dir = Rails.root.join('test/reports/minitest').to_s

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  setup :load_seeds

  teardown :clear_cache

  protected

  def load_seeds
    Rails.application.load_seed
    RequestContext.community = Community.first
  end

  def clear_cache
    Rails.cache.clear
  end
end

class ActionController::TestCase
  setup :load_host

  def load_host
    request.env['HTTP_HOST'] = Community.first.host
  end
end

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

  setup :load_seeds

  teardown :clear_cache

  protected

  def load_seeds
    comm = Community.first || Community.create(name: 'Test', host: 'test.host')
    RequestContext.community = comm
    Rails.application.load_seed
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

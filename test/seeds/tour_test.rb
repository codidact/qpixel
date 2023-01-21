require 'test_helper'

class TourTest < ActiveSupport::TestCase
  test 'Tour question tag set exists for all communities after seeding' do
    # Ensure there are multiple communities
    Community.create(name: 'Test 1', host: 'test.host.1')
    Community.create(name: 'Test 2', host: 'test.host.2')

    Rails.application.load_seed

    # Every community should have the Tour tagset
    Community.all.each do |c|
      assert_not_nil TagSet.unscoped.where(community: c).find_by(name: 'Tour')
    end
  end
end

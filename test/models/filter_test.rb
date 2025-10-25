require 'test_helper'

class FilterTest < ActiveSupport::TestCase
  test 'system? should correctly determine if a filter is a system filter' do
    sys_usr = users(:system)

    filters.each do |filter|
      assert_equal filter.system?, filter.user_id == sys_usr
    end
  end
end

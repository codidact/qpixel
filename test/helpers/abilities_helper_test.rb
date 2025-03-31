require 'test_helper'

class AbilitiesHelperTest < ActionView::TestCase
  include Devise::Test::ControllerHelpers

  test 'linearize_progress works as expected' do
    expected = [[0.2, 0], [0.5, 0.0], [0.98, 95.99999999999991], [0.99, 195.99999999999983]]
    expected.each do |score, exp|
      assert_equal exp, linearize_progress(score)
    end
  end
end

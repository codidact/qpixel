require 'test_helper'

class RecalcAbilitiesTest < ActiveSupport::TestCase
  test 'should correctly run the script' do
    assert_nothing_raised do
      system('bundle exec rails runner scripts/recalc_abilities.rb', exception: true)
    end
  end
end

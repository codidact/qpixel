require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  test 'score_percent_for methods should return 0 for missing users' do
    [:edit, :flag, :post].each do |type|
      abilities.each do |ability|
        assert_equal 0, ability.send("#{type}_score_percent_for", nil)
      end
    end
  end

  test 'score_percent_for methods should return 0 for unrelated abilities' do
    std = users(:standard_user)

    [:edit, :flag, :post].each do |type|
      abilities.each do |ability|
        next unless ability.send("#{type}_score_threshold").nil?

        assert_equal 0, ability.send("#{type}_score_percent_for", std)
      end
    end
  end

  test 'score_percent_for methods should return 100 for abilities 0 thresholds' do
    std = users(:standard_user)

    [:edit, :flag, :post].each do |type|
      abilities.each do |ability|
        next unless ability.send("#{type}_score_threshold")&.zero?

        assert_equal 100, ability.send("#{type}_score_percent_for", std)
      end
    end
  end

  test 'edit_score_percent_for should correctly calculate percent for a given user' do
    user = users(:partial_edit_scorer)
    ability = abilities(:edit_posts)

    assert_equal 2, ability.edit_score_percent_for(user)
  end

  test 'flag_score_percent_for should correctly calculate percent for a given user' do
    user = users(:partial_flag_scorer)
    ability = abilities(:flag_curate)

    assert_equal 6, ability.flag_score_percent_for(user)
  end
end

require 'test_helper'

class AbilityQueueTest < ActiveSupport::TestCase
  test 'should correctly add queue entries' do
    flag = flags(:one)
    std_usr = users(:standard_user)
    comment = "Flag Handled ##{flag.id}"

    valid = AbilityQueue.add(std_usr, comment)
    assert valid.persisted?
    assert_equal valid.comment, comment
    assert_equal valid.community_user, std_usr.community_user
  end

  test 'should correctly add! queue entries' do
    flag = flags(:one)
    std_usr = users(:standard_user)
    comment = "Flag Handled ##{flag.id}"

    assert_nothing_raised do
      AbilityQueue.add!(std_usr, comment)
    end
  end
end

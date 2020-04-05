require 'test_helper'

class SuspiciousVoteTest < ActiveSupport::TestCase
  test 'check_for_vote_fraud should not throw exceptions' do
    assert_nothing_raised do
      SuspiciousVote.check_for_vote_fraud
    end
  end
end

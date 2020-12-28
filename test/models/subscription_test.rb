require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
    assert_community_related(Subscription)
  end

  test 'subscription to all should return some questions' do
    questions = subscriptions(:all).questions
    assert_not_nil questions
    assert_not questions.empty?, 'No questions returned'
    assert questions.size <= 100, 'Too many questions returned'
  end

  test 'tag subscription should return only tag questions' do
    questions = subscriptions(:tag).questions
    assert_not_nil questions
    assert_not questions.empty?, 'No questions returned'
    assert questions.size <= 100, 'Too many questions returned'
    questions.each do |question|
      assert question.tags.map(&:name).include?(subscriptions(:tag).qualifier),
             "Tag subscription returned question #{question.id} without specified tag"
    end
  end

  test 'user subscription should return only user questions' do
    questions = subscriptions(:user).questions
    assert_not_nil questions
    assert_not questions.empty?, 'No questions returned'
    assert questions.size <= 100, 'Too many questions returned'
    questions.each do |question|
      assert question.user_id == subscriptions(:user).qualifier.to_i,
             "User subscription returned question #{question.id} not from specified user"
    end
  end
end

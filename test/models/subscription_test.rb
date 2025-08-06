require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
    assert_community_related(Subscription)
  end

  test 'subscription to all should return some questions' do
    questions = subscriptions(:all).questions

    assert_questions_valid(questions)
  end

  test 'tag subscription should return only tag questions' do
    questions = subscriptions(:tag).questions

    assert_questions_valid(questions)
    questions.each do |question|
      assert question.tags.map(&:name).include?(subscriptions(:tag).qualifier),
             "Tag subscription returned question #{question.id} without specified tag"
    end
  end

  test 'user subscription should return only user questions' do
    questions = subscriptions(:user).questions

    assert_questions_valid(questions)
    questions.each do |question|
      assert question.user_id == subscriptions(:user).qualifier.to_i,
             "User subscription returned question #{question.id} not from specified user"
    end
  end

  test 'interesting subscription should return only questions with score higher than the threshold' do
    threshold = 0.5

    SiteSetting['InterestingSubscriptionScoreThreshold'] = threshold

    questions = subscriptions(:interesting).questions

    assert_questions_valid(questions)
    questions.each do |question|
      assert question.score >= threshold,
             "Expected question #{question.id} with a score of #{question.score} to be excluded"
    end
  end

  test 'category subscription should return only questions from a specific category' do
    category = categories(:main)
    questions = subscriptions(:category).questions

    assert_questions_valid(questions)
    questions.each do |question|
      assert question.category == category,
             "Expected quesiton #{question.id} to be from the #{category.name} category," \
             "actual: #{question.category.name || 'no category'}"
    end
  end

  test 'qualified? should correctly determine if a subscription should have a qualifier' do
    subscriptions.each do |sub|
      assert_equal sub.qualified?, Subscription::QUALIFIED_TYPES.include?(sub.type)
    end
  end

  test 'prediactes for each type should correctly determine if the subscription is of type' do
    Subscription::TYPES.each do |type|
      other_types = Subscription::TYPES.reject { |t| t == type }
      subscription = Subscription.new(type: type)

      assert subscription.send("#{type}?")
      assert(other_types.none? { |t| subscription.send("#{t}?") })
    end
  end

  private

  def assert_questions_valid(questions)
    assert_not_nil(questions)
    assert_not(questions.empty?, 'No questions returned')
    assert(questions.size <= 100, 'Too many questions returned')
  end
end

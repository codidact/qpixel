require 'test_helper'

class RequestContextTest < ActiveSupport::TestCase
  test 'initialized context store accessor' do
    RequestContext.community = :foo
    RequestContext.user = :bar
    assert_equal RequestContext.fetch, {community: :foo, user: :bar}
  end

  test 'cleared context store' do
    RequestContext.clear!
    assert_equal RequestContext.fetch, {}
  end

  test "community accessors" do
    @community = Community.new(id: 17)
    RequestContext.community = @community
    assert_equal RequestContext.community, @community
    assert_equal RequestContext.community_id, @community.id
  end

  test "user accessors" do
    @user = User.new(id: 17)
    RequestContext.user = @user
    assert_equal RequestContext.user, @user
    assert_equal RequestContext.user_id, @user.id
  end

  class NonThreadSafe
    cattr_accessor :community
  end

  test "thread safety" do
    @community1 = Community.new(id: 17)
    @community2 = Community.new(id: 18)
    @community3 = Community.new(id: 19)
    RequestContext.community = @community1
    NonThreadSafe.community = @community1   # as a baseline, to demonstrate non-thread safe behavior

    worker1 = Thread.new do
      RequestContext.community = @community2
      NonThreadSafe.community = @community2
      sleep 0.5

      # this check runs second
      assert_equal RequestContext.community, @community2
      assert_not_equal NonThreadSafe.community, @community2
    end

    worker2 = Thread.new do
      RequestContext.community = @community3
      NonThreadSafe.community = @community3

      # this check runs first
      assert_equal RequestContext.community, @community3
      assert_equal NonThreadSafe.community, @community3
    end
    worker1.join(0.1) # run worker1 until sleep
    worker2.join(0.5) # run worker2 to completion
    worker1.join      # finalize worker1

    # this check runs last
    assert_equal RequestContext.community, @community1
    assert_not_equal NonThreadSafe.community, @community1
  end
end

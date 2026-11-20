require 'test_helper'

class PinnedLinkTest < ActiveSupport::TestCase
  test ':timed scope should only return time-constrained links' do
    timed = PinnedLink.timed

    assert timed.any?
    timed.each do |link|
      assert link.timed?, "link \"#{link.label}\" is not timed"
    end
  end

  test ':current scope should return non-timed or current links' do
    now = DateTime.now
    current = PinnedLink.current

    assert current.any?
    current.each do |link|
      assert link.current?(now)
    end
  end

  test ':past scope should only return past links' do
    now = DateTime.now
    past = PinnedLink.past

    assert past.any?
    past.each do |link|
      assert link.past?(now)
    end
  end

  test ':future scope should only return future links' do
    now = DateTime.now
    future = PinnedLink.future

    assert future.any?
    future.each do |link|
      assert link.future?(now)
    end
  end

  test 'pinned links should be correctly validated' do
    valid_with_link = PinnedLink.new(link: 'https://example.com')
    valid_with_post = PinnedLink.new(post: posts(:question_one))
    period_mismatch = PinnedLink.new(shown_before: DateTime.now - 1, shown_after: DateTime.now)

    [
      [valid_with_link, true],
      [valid_with_post, true],
      [period_mismatch, false]
    ].each do |test|
      link, status = test
      assert_equal status, link.valid?
    end
  end
end

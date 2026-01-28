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
      assert !link.timed? || (link.shown_before > now && link.shown_after <= now)
    end
  end

  test ':past scope should only return past links' do
    now = DateTime.now
    past = PinnedLink.past

    assert past.any?

    past.each do |link|
      assert link.timed? && link.shown_before < now
    end
  end

  test ':future scope should only return future links' do
    now = DateTime.now
    future = PinnedLink.future

    assert future.any?

    future.each do |link|
      assert link.timed? && link.shown_before > now && link.shown_after > now
    end
  end
end

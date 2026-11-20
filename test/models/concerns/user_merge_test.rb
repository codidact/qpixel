require 'test_helper'

class UserMergeTest < ActiveSupport::TestCase
  test 'merge_into should destroy the old user upon success' do
    merger = users(:global_admin)
    src_usr = users(:merge_source)
    tgt_usr = users(:merge_target)

    src_usr.merge_into(tgt_usr, merger)

    assert_raises ActiveRecord::RecordNotFound do
      src_usr.reload
    end
  end

  test 'merge_info should move followed threads / posts to the target user' do
    merger = users(:global_admin)
    src_usr = users(:merge_source)
    tgt_usr = users(:merge_target)

    src_new_threads_followed = NewThreadFollower.where(user: src_usr)
    src_new_threads_followed_ids = src_new_threads_followed.map(&:id)
    assert src_new_threads_followed_ids.any?

    src_threads_followed = ThreadFollower.where(user: src_usr)
    src_threads_followed_ids = src_threads_followed.map(&:id)
    assert src_threads_followed_ids.any?

    src_usr.merge_into(tgt_usr, merger)

    src_new_threads_followed.reload
    src_threads_followed.reload

    assert src_new_threads_followed.none?
    assert src_threads_followed.none?

    tgt_new_threads_followed = NewThreadFollower.where(id: src_new_threads_followed_ids)
    tgt_threads_followed = ThreadFollower.where(id: src_threads_followed_ids)

    assert tgt_new_threads_followed.any?
    assert(tgt_new_threads_followed.all? { |a| a.user.same_as?(tgt_usr) })

    assert tgt_threads_followed.any?
    assert(tgt_threads_followed.all? { |a| a.user.same_as?(tgt_usr) })
  end
end

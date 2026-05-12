class FollowOwnPosts < ActiveRecord::Migration[7.2]
  def change
    to_insert = Post.unscoped
                    .where.not(post_type_id: [PolicyDoc.post_type_id, HelpDoc.post_type_id])
                    .where.not(user_id: nil)
                    .pluck(:id, :user_id)
                    .map { |post_id, user_id| { post_id: post_id, user_id: user_id } }

    NewThreadFollower.insert_all(to_insert)
  end
end

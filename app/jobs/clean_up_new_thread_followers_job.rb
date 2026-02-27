class CleanUpNewThreadFollowersJob < ApplicationJob
  queue_as :default

  def perform
    sql = File.read(Rails.root.join('db/scripts/posts_with_duplicate_new_thread_followers.sql'))
    posts = ActiveRecord::Base.connection.execute(sql).to_a

    posts.each do |post|
      user_id, post_id = post

      followers = NewThreadFollower.where(post_id: post_id, user_id: user_id)

      next unless followers.many?

      duplicate = followers.first
      result = duplicate.destroy

      unless result
        logger.warn "Failed to destroy new thread follower duplicate \"#{duplicate.id}\. Validations follow."
        duplicate.errors.full_messages.each do |msg|
          logger.warn msg
        end
        duplicate.errors.each { |e| puts e.full_message }
      end
    end

    logger.info "Processed #{posts.size} posts."
  end
end

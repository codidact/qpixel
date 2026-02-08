class CleanUpThreadFollowersJob < ApplicationJob
  queue_as :default

  def perform
    sql = File.read(Rails.root.join('db/scripts/threads_with_duplicate_followers.sql'))
    threads = ActiveRecord::Base.connection.execute(sql).to_a

    threads.each do |thread|
      user_id, thread_id = thread

      followers = ThreadFollower.where(comment_thread_id: thread_id, user_id: user_id)

      next unless followers.many?

      duplicate = followers.first
      result = duplicate.destroy

      unless result
        puts "failed to destroy thread follower duplicate \"#{duplicate.id}\""
        duplicate.errors.each { |e| puts e.full_message }
      end
    end
  end
end

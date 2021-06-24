Post.unscoped.where(id: Comment.unscoped.where(comment_thread: nil)
                               .select(Arel.sql('distinct post_id'))).each do |post|
  comments = Comment.unscoped.where(post: post, comment_thread: nil)
  next unless comments.any?

  comments = comments.all

  new_thread = CommentThread.new(title: 'General comments', post: post, reply_count: comments.size, locked: false,
                                 archived: false, deleted: false, community: post.community)
  new_thread.save

  comments.update_all(comment_thread_id: new_thread.id)

  puts "#{comments.size} comments updated for post Id=#{post.id}"
end
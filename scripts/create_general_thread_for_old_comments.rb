Post.unscoped.each do |post|
  comments = Comment.unscoped.where(post: post, comment_thread: nil)
  next unless comments.any?

  comments = comments.all

  new_thread = CommentThread.new(title: 'General comments', post: post, reply_count: comments.size, locked: false,
                                 archived: false, deleted: false, community: post.community)
  new_thread.save

  comments.each do |c|
    c.update comment_thread: new_thread
  end

  puts "#{comments.size} comments updated for post Id=#{post.id}"
end
module UserRateLimits
  extend ActiveSupport::Concern

  # Gets the max number of comments the user can make per day on posts made by other users
  # @return [Integer]
  def max_comments_per_day_on_posts_of_others
    SiteSetting[new? ? 'RL_NewUserComments' : 'RL_Comments'] || 0
  end

  # Gets the max number of comments the user can make per day on their own posts or answers to them
  # @return [Integer]
  def max_comments_per_day_on_own_posts
    SiteSetting[new? ? 'RL_NewUserCommentsOwnPosts' : 'RL_CommentsOwnPosts'] || 0
  end

  # Gets the max number of comments the user can make on a given post
  # @param post [Post] post to get the limit for
  # @return [Integer]
  def max_comments_per_day(post)
    owns_post_or_parent?(post) ? max_comments_per_day_on_own_posts : max_comments_per_day_on_posts_of_others
  end

  # Gets the max number of votes the user can make per day
  # @return [Integer]
  def max_votes_per_day
    SiteSetting[new? ? 'RL_NewUserVotes' : 'RL_Votes'] || 0
  end

  # Number of comments by the user based on whether they own a given post
  # @param post [Post] post to use for the check
  # @return [Integer]
  def recent_comments_count(post)
    owns_post_or_parent?(post) ? recent_comments_on_own_posts_count : recent_comments_on_posts_of_others_count
  end

  # Number of comments by the user on own posts or answers to them in the last 24 hours
  # @return [Integer]
  def recent_comments_on_own_posts_count
    Comment.recent.by(self)
           .where(post: Post.parent_by(self))
           .or(Comment.recent.by(self).where(post: Post.by(self)))
           .count
  end

  # Number of comments by the user on posts made by other users in the last 24 hours
  # @return [Integer]
  def recent_comments_on_posts_of_others_count
    Comment.recent.by(self)
           .where.not(post: Post.parent_by(self))
           .where.not(post: Post.by(self))
           .count
  end

  # Number of votes by the user on posts of others in the last 24 hours
  # @return [Integer] number of recent votes
  def recent_votes_count
    Vote.recent.by(self).where.not(post: Post.parent_by(self)).count
  end

  # Has the user reached comment limit for a given post?
  # @param post [Post] post to check
  # @return [Boolean] check result
  def comment_rate_limited?(post)
    recent_comments_count(post) >= max_comments_per_day(post)
  end
end

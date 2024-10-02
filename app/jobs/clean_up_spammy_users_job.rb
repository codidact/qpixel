class CleanUpSpammyUsersJob < ApplicationJob
  queue_as :default

  def perform(created_after: 1.month.ago)
    # Select potential spammers: users created within timeframe, who are not deleted, who have posted but all posts have
    # since been deleted (no live posts).
    possible_spammers = User.joins('inner join posts on users.id = posts.user_id')
                            .where('users.created_at >= ?', created_after)
                            .where(users: { deleted: false }).group('users.id').having('count(posts.id) > 0')
                            .having('count(distinct if(posts.deleted = true, null, posts.id)) = 0')
    possible_spammers.each do |spammer|
      all_posts_spam = spammer.posts.all? do |post|
        # A post is considered spam if there are any helpful spam flags on it.
        post.flags.any? { |flag| flag.post_flag_type.name == "it's spam" && flag.status == 'helpful' }
      end
      if all_posts_spam
        spammer.block('automatic block from spam cleanup job', length: 2.years)
      end
    end
  end
end

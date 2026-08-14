class DeleteUserJob < ApplicationJob
  queue_as :default

  def perform(user, attribute_to, perform_spam_check: true)
    user.soft_delete(attribute_to)

    if perform_spam_check
      # Can't use model helper methods very easily here, because we want network-wide flags and that doesn't play
      # nicely with default scopes.
      flag_query = Post.unscoped
                       .joins(Arel.sql("INNER JOIN flags ON flags.post_type = 'Post' AND flags.post_id = posts.id"))
                       .joins(Arel.sql('INNER JOIN post_flag_types ON flags.post_flag_type_id = post_flag_types.id'))
                       .where(flags: { status: 'helpful' },
                              post_flag_types: { name: "it's spam" },
                              posts: { user_id: user.id })
      if flag_query.any?
        user.block('automatic block from spam check during deletion')
      end
    end
  end
end

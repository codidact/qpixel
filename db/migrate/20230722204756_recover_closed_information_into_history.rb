class RecoverClosedInformationIntoHistory < ActiveRecord::Migration[7.0]
  def change
    pht = PostHistoryType.find_by(name: 'question_closed')

    # For all history where the post is still closed, add the close reason and duplicate post id.
    # We need to only add it to the last post closure (for close, reopen, close cases), so we do a left join with
    # post histories in a way where we only retrieve the closed history event with the last created_at date.

    # NOTE: Ideally we would do a `joins(:post).includes(post: [:close_reason]).find_each` to achieve the same result in
    #       a pure Rails way as this uncached, unscoped, in_batches, pluck mess.
    #       However, the default_scopes which limit to a specific community seem to apply on the includes relations,
    #       adding where clauses on the "current" community (i.e. community IS NULL) on them...
    #       Given the potential amount of history items we are dealing with, we therefore have to instead do this fun
    #       workaround.
    PostHistory.uncached do
      PostHistory.unscoped.in_batches do |relation|
        relation.joins(Arel.sql('INNER JOIN `posts` ON `post_histories`.`post_id` = `posts`.`id`'))
                .joins(Arel.sql('LEFT JOIN `close_reasons` ON `posts`.`close_reason_id` = `close_reasons`.`id`'))
                .where(post_history_type: pht)
                .where(posts: { closed: true })
                .joins(Arel.sql(<<-SQL
                        LEFT JOIN `post_histories` `ph`
                        ON `ph`.`post_id` = `post_histories`.`post_id`
                        AND `post_histories`.`created_at` < `ph`.`created_at`
                        AND `ph`.`post_history_type_id` = #{pht.id}
                SQL
                ))
                .where(Arel.sql('`ph`.`created_at` IS NULL'))
                .pluck(Arel.sql('post_histories.id, close_reasons.id, close_reasons.name, posts.duplicate_post_id'))
                .each do |r|
          post_history_id = r[0]
          close_reason_id = r[1]
          close_reason_name = r[2] || '<DELETED REASON>'
          duplicate_post_id = r[3]

          if duplicate_post_id
            comment = "Closed as #{close_reason_name} of [Question ##{duplicate_post_id}](/posts/#{duplicate_post_id})"
          else
            comment = "Closed as #{close_reason_name}"
          end

          # Prevent loading the post history by doing `where(id: ...).update_all`, which will directly run an UPDATE
          # query.
          PostHistory.where(id: post_history_id)
                     .update_all(comment: comment,
                                 close_reason_id: close_reason_id,
                                 duplicate_post_id: duplicate_post_id)
        end
      end
    end
  end
end

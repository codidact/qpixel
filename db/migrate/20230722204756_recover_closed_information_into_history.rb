class RecoverClosedInformationIntoHistory < ActiveRecord::Migration[7.0]
  def change
    # For all history where the post is still closed, add the close reason and duplicate post id.
    # We need to only add it to the last post closure (for close, reopen, close cases), so we order by created_at
    # and skip elements for posts we already saw.
    seen = Set[]
    PostHistory.all.where(post_history_type: PostHistoryType.find_by(name: 'question_closed'))
               .joins(:post).where(posts: { closed: true }).includes(post: %i[close_reason])
               .order(created_at: :desc)
               .each do |ph|
      next unless seen.add?(ph.post_id)
      close_reason = ph.post.close_reason
      duplicate_post_id = ph.post.duplicate_post_id
      if duplicate_post_id
        comment = "Closed as #{close_reason.name} of [Question ##{duplicate_post_id}](/posts/#{duplicate_post_id})"
      else
        comment = "closed as #{close_reason.name}"
      end

      ph.update_columns(comment: comment, extra: {
        close_reason_id: close_reason.id,
        duplicate_post_id: duplicate_post_id
      })
    end
  end
end
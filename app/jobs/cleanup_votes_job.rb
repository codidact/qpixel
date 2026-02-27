class CleanupVotesJob < ApplicationJob
  queue_as :default

  def perform
    Community.all.each do |c|
      logger.tagged(c.name) do
        RequestContext.community = c
        orphan_votes = Vote.all.reject { |v| v.post.present? }

        logger.info "Removing #{orphan_votes.length} #{'orphan vote'.pluralize(orphan_votes.length)}"

        system_user = User.find(-1)

        orphan_votes.each do |v|
          result = v.destroy

          if result
            AuditLog.admin_audit(
              comment: "Deleted orphaned vote for user ##{v.recv_user_id} " \
                       "on post ##{v.post_id} " \
                       "in community ##{c.id} (#{c.name})",
              event_type: 'vote_delete',
              related: v,
              user: system_user
            )
          else
            logger.warn "Failed to remove vote #{v.id}. Validations follow."
            v.errors.full_messages.each do |msg|
              logger.warn msg
            end
          end
        end
      end
    end
  end
end

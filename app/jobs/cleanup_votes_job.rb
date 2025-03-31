class CleanupVotesJob < ApplicationJob
  queue_as :default

  def perform
    Community.all.each do |c|
      RequestContext.community = c
      orphan_votes = Vote.all.reject { |v| v.post.present? }

      puts "[#{c.name}] destroying #{orphan_votes.length} #{'orphan vote'.pluralize(orphan_votes.length)}"

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
          puts "[#{c.name}] failed to destroy vote \"#{v.id}\""
          v.errors.each { |e| puts e.full_message }
        end
      end
    end
  end
end

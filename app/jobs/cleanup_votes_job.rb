class CleanupVotesJob < ApplicationJob
  queue_as :default

  def perform
    Community.all.each do |c|
      RequestContext.community = c
      orphan_votes = Vote.all.reject { |v| v.post.present? }
      puts "[#{c.name}] destroying #{orphan_votes.length} #{'orphan vote'.pluralize(orphan_votes.length)}"
      failed = orphan_votes.reject(&:destroy)

      failed.each do |v|
        puts "[#{c.name}] failed to destroy vote \"#{v.id}\""
        v.errors.each { |e| puts e.full_message }
      end
    end
  end
end

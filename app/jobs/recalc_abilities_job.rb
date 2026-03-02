class RecalcAbilitiesJob < ApplicationJob
  queue_as :default

  ##
  # Perform ability recalculations.
  # @param options [OpenStruct] additional options for the job. Currently supports +verbose+ and +quiet+.
  def perform(options)
    resolved = []
    destroy = []
    all = AbilityQueue.pending.to_a

    all.each do |q|
      begin
        cu = q.community_user
        u = cu&.user

        if cu.nil? || u.nil?
          destroy << q.id
          next
        end

        RequestContext.community = cu.community

        if options.verbose && !options.quiet
          logger.debug "Scope: Community     : #{cu.community.name} (#{cu.community.host})"
          logger.debug "       User          : #{u.username} (#{cu.user_id})"
          logger.debug "       CommunityUser : #{cu.id}"
        elsif !options.verbose && !options.quiet
          logger.debug "Scope: CommunityUser : #{cu.id}"
        end

        cu.recalc_abilities!

        # Grant mod ability if mod status is given
        if cu.at_least_moderator? && !cu.ability?('mod')
          cu.grant_ability!('mod')
        end

        resolved << q.id
      rescue => e
        logger.error "  Failed: #{e.class.name}: #{e.message}"
        logger.error e.backtrace

        if Rails.env.test?
          raise e
        end
      end
    end

    AbilityQueue.where(id: resolved).update(completed: true)
    AbilityQueue.where(id: destroy).delete_all

    unless options.quiet
      logger.info "Completed, #{resolved.size}/#{all.size} tasks successful, #{destroy.size} tasks invalid"
    end
  end
end

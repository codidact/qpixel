class CheckCIDRJob < ApplicationJob
  queue_as :default

  def perform(post)
    @post = post
    relevant_ips = [post.user.current_sign_in_ip, post.user.last_sign_in_ip]
    prefixes = BlockedItem.where(item_type: 'ip_prefix')
                          .where(Arel.sql('expires >= CURRENT_TIMESTAMP'))
                          .where("? LIKE CONCAT(`value`, '%') OR ? LIKE CONCAT(`value`, '%')", *relevant_ips)

    if prefixes.any?
      create_flag prefixes[0]
      return # because prefixes are more performant than CIDR checks, so if we can match there then that'll do
    end

    cidrs = BlockedItem.where(item_type: 'ip_cidr')
                       .where(Arel.sql('expires >= CURRENT_TIMESTAMP'))
    cidrs.each do |cidr|
      network = IPAddress.parse(cidr.value)
      relevant_ips.each do |ip|
        ip = IPAddress.parse(ip)
        # rubocop:disable Style/Next
        if network.include?(ip)
          create_flag cidr
          # rubocop:disable Lint/NonLocalExitFromIterator
          return
          # rubocop:enable Lint/NonLocalExitFromIterator
        end
        # rubocop:enable Style/Next
      end
    end
  end

  def create_flag(match)
    reason = 'Automatically escalated spam flag - please leave this for the community team to handle.'
    spam_flag_type = PostFlagType.unscoped.where(community: @post.community, name: "it's spam").first
    flag = @post.flags.create(user: helpers.system_user, community: @post.community, post_flag_type: spam_flag_type,
                              reason: reason, escalated: true, escalated_at: DateTime.now,
                              escalated_by: helpers.system_user,
                              escalation_comment: "Suspicious IP address: user IP matches #{match.value}")
    FlagMailer.with(flag: flag).flag_escalated.deliver_now
  end

  def helpers
    ApplicationController.helpers
  end
end

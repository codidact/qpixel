module UserMerge
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength
  included do
    def merge_into(target_user, attribute_to)
      transaction do
        community_users = CommunityUser.where(user_id: [id, target_user.id])
        cu_map = community_users.group_by(&:user_id)
        cu_ids = {}
        cu_map[id].each do |cu|
          source_cu_id = cu.id
          target_cu = cu_map[target_user.id].select { |tu| tu.community_id == cu.community_id }
          target_cu_id = if target_cu.empty?
                           CommunityUser.create(community: cu.community, user: target_user, reputation: 1)
                         else
                           target_cu[0].id
                         end
          cu_ids[cu.community_id] = { source: source_cu_id, target: target_cu_id }
        end

        copy_abilities(target_user, cu_ids)

        AuditLog.where(user_id: id).update_all(user_id: target_user.id)
        AuditLog.where(related_type: 'User', related_id: id).update_all(related_id: target_user.id)

        Comment.where(user_id: id).update_all(user_id: target_user.id)
        update_thread_references(target_user)

        ErrorLog.where(user_id: id).update_all(user_id: target_user.id)

        Flag.where(user_id: id).update_all(user_id: target_user.id)
        Flag.where(handled_by_id: id).update_all(handled_by_id: target_user.id)

        Notification.where(user_id: id).update_all(user_id: target_user.id)
        PostHistory.where(user_id: id).update_all(user_id: target_user.id)

        Post.where(user_id: id).update_all(user_id: target_user.id)
        update_post_action_references(target_user)

        Subscription.where(user_id: id).update_all(user_id: target_user.id)

        SuggestedEdit.where(user_id: id).update_all(user_id: target_user.id)
        SuggestedEdit.where(decided_by_id: id).update_all(decided_by_id: target_user.id)

        copy_votes(target_user)
        copy_warnings(target_user, cu_ids)

        AuditLog.user_history event_type: 'user_merge', related: target_user, user: attribute_to,
                              comment: "Merged ##{id} (#{username}) into ##{target_user.id} (#{target_user.username})"
        AuditLog.pii_history event_type: 'user_merge', related: target_user, user: attribute_to,
                             comment: "Source: ##{id}\n#{email}\n#{current_sign_in_ip}\n#{last_sign_in_ip}"
        destroy!
      end
    end

    private

    def copy_abilities(_target_user, cu_ids)
      cu_ids.each do |_cid, ids|
        target_abilities = UserAbility.where(community_user_id: ids[:target])
        copy_abilities = UserAbility.where(community_user_id: ids[:source])
                                    .where.not(ability_id: target_abilities.map(&:ability_id).uniq)
        copy_abilities.update_all(community_user_id: ids[:target])
        UserAbility.where(community_user_id: ids[:source]).destroy_all
      end
    end

    def update_thread_references(target_user)
      CommentThread.where(locked_by_id: id).update_all(locked_by_id: target_user.id)
      CommentThread.where(archived_by_id: id).update_all(archived_by_id: target_user.id)
      CommentThread.where(deleted_by_id: id).update_all(deleted_by_id: target_user.id)
      ThreadFollower.where(user_id: id).update_all(user_id: target_user.id)
    end

    def update_post_action_references(target_user)
      Post.where(closed_by_id: id).update_all(closed_by_id: target_user.id)
      Post.where(deleted_by_id: id).update_all(deleted_by_id: target_user.id)
      Post.where(last_activity_by_id: id).update_all(last_activity_by_id: target_user.id)
      Post.where(last_edited_by_id: id).update_all(last_edited_by_id: target_user.id)
      Post.where(locked_by_id: id).update_all(locked_by_id: target_user.id)
    end

    def copy_votes(target_user)
      Vote.where(user_id: id).where.not(recv_user_id: target_user.id).update_all(user_id: target_user.id)
      Vote.where(user_id: id).delete_all # delete_all not destroy_all - we'll run a recalc, no need for callbacks
    end

    def copy_warnings(_target_user, cu_ids)
      cu_ids.each do |_cid, ids|
        ModWarning.where(community_user_id: ids[:source]).update_all(community_user_id: ids[:target])
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end

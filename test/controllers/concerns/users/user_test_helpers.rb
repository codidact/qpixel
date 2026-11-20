module UserTestHelpers
  extend ActiveSupport::Concern

  included do
    private

    def create_other_user
      other_community = Community.create(host: 'other.qpixel.com', name: 'Other')
      RequestContext.redis.hset('network/community_registrations', 'other@example.com', other_community.id)
      other_user = User.create!(email: 'other@example.com', password: 'abcdefghijklmnopqrstuvwxyz', username: 'other_user')
      other_user.community_users.create!(community: other_community)
      other_user
    end

    # @param type [String] deletion type (user or profile)
    # @param user [User] user to soft delete
    def try_soft_delete_user(type, user)
      perform_enqueued_jobs do
        delete :soft_delete, params: { id: user.id,
                                       type: type,
                                       format: :json }
      end
    end

    def try_save_preference(name, value, community: nil)
      post :set_preference, params: {
        community: community,
        name: name,
        value: value,
        format: :json
      }
    end

    # @param user [User] user to undelete
    def try_undelete_user(user)
      post :undelete, params: { id: user.id,
                                format: :json }
    end
  end
end

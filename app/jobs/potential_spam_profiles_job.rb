class PotentialSpamProfilesJob < ApplicationJob
  queue_as :default

  def perform
    sql = File.read(Rails.root.join('db/scripts/potential_spam_profiles.sql'))
    sql = sql.gsub('$HOURS', '25')
    user_ids = ActiveRecord::Base.connection.execute(sql).to_a.flatten
    users = User.where(id: user_ids)

    ability_ids = Ability.unscoped.where(internal_id: 'unrestricted').map(&:id)

    users.each do |user|
      cu_ids = user.community_users.map(&:id)
      UserAbility.where(community_user_id: cu_ids, ability_id: ability_ids)
                 .update_all(is_suspended: true, suspension_message: 'This ability has been automatically suspended.')
    end
  end
end

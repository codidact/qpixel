class FixInterestingSubscriptionScoreThresholdSiteSetting < ActiveRecord::Migration[7.2]
  def up
    SiteSetting.unscoped
               .where(name: 'FixInterestingSubscriptionSiteSetting', value_type: 'integer')
               .update_all(value_type: 'float')
  end

  def down
    # noop, this is intentionally not idempotent
    # the setting should've never been an integer
  end
end

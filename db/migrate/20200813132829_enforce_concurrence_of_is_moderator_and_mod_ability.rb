class EnforceConcurrenceOfIsModeratorAndModAbility < ActiveRecord::Migration[5.2]
  def up
    CommunityUser.unscoped.where(is_moderator: true).all.map do |cu|
      RequestContext.community = cu.community
      cu.grant_privilege  'mod'
    end
  end

  def down
    # Nothing to do, because the up only duplicates content,
    # which cannot be easily reversed without likely quite
    # complex algorithmis. This is unneccessary, because the duplicate
    # content isn't harmful in any way.
  end
end

class DisableNeedsAuthorAttentionFlag < ActiveRecord::Migration[7.0]
  def up
    PostFlagType.unscoped.where(name: "needs author's attention").update_all(active: false)
  end

  def down
    PostFlagType.unscoped.where(name: "needs author's attention").update_all(active: true)
  end
end

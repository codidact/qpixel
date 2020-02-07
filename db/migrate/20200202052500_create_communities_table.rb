class CreateCommunitiesTable < ActiveRecord::Migration[5.2]
  # helper User model without delegation for migration purposes
  class MigrationSafeUser < ActiveRecord::Base; self.table_name = 'users'; end

  def change
    create_table :communities do |t|
      t.string :name, null: false
      t.string :host, null: false, index: true
      t.timestamps
    end

    create_table :community_users do |t|
      t.references :community, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.boolean :is_moderator
      t.boolean :is_admin
      t.integer :reputation
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        @community = Community.create(name: 'Sample', host: 'sample.qpixel.com')
        community_users = MigrationSafeUser.pluck(:id, :reputation).map do |user_id, reputation|
          {community_id: @community.id, user_id: user_id, reputation: reputation}
        end
        CommunityUser.create(community_users)
        change_table :users do |t|
          t.rename :is_moderator, :is_global_moderator
          t.rename :is_admin, :is_global_admin
          t.remove :reputation
        end
      end
      dir.down do
        change_table :users do |t|
          t.rename :is_global_moderator, :is_moderator
          t.rename :is_global_admin, :is_admin
          t.integer :reputation, after: 'is_admin'
        end
        @community = Community.first
        CommunityUser.where(community_id: @community.id).pluck(:user_id,:reputation).map do |user_id, reputation|
          MigrationSafeUser.find(user_id).update(reputation: reputation)
        end
      end
    end

    %i(posts comments flags post_histories votes
       notifications privileges site_settings subscriptions tags
      ).each do |table|
      change_table table do |t|
        t.references :community
      end

      unless table == :site_settings
        reversible do |dir|
          dir.up do
            table.to_s.classify.constantize.unscoped.update_all(community_id: @community.id)
          end
        end

        change_column_null table, :community_id, false
      end

      add_foreign_key table, :communities
    end
  end
end

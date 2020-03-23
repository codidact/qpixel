class AddTagSetReferenceToTags < ActiveRecord::Migration[5.2]
  def change
    add_reference :tags, :tag_set, index: true
    Community.all.each do |community|
      RequestContext.community = community
      main_set = TagSet.find_or_create_by(community: community, name: 'Main')
      meta_set = TagSet.find_or_create_by(community: community, name: 'Meta')
      sql = "select tag_id from posts_tags where post_id in (select id from posts where community_id = #{community.id} and category = '$cat')"
      main_sql = sql.gsub('$cat', 'Main')
      meta_sql = sql.gsub('$cat', 'Meta')
      update_sql = "update tags set tag_set_id = $tsid where id in ($sql);"
      ActiveRecord::Base.connection.execute update_sql.gsub('$tsid', main_set.id.to_s).gsub('$sql', main_sql)
      ActiveRecord::Base.connection.execute update_sql.gsub('$tsid', meta_set.id.to_s).gsub('$sql', meta_sql)
    end
    ActiveRecord::Base.connection.execute "delete from tags where tag_set_id is null;"
    change_column_null :tags, :tag_set_id, false
  end
end

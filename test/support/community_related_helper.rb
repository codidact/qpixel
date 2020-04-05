module CommunityRelatedHelper
  def assert_community_related(model)
    assert model.reflections['community'].present?, 'Community association missing'
    assert_equal model.new.community, RequestContext.community, 'Default scope should use context community'
    quoted = model.connection.quote_column_name('community_id')
    assert model.all.to_sql.include?("#{quoted} = #{RequestContext.community_id}"),
           'Default scope should use context community'
  end

  def assert_post_related(model)
    assert model.reflections['post'].present?, 'Post association missing'
    assert_community_related(model)
  end
end

require 'test_helper'

class SiteSettingTest < ActiveSupport::TestCase
  test 'string values should be correctly typed' do
    SiteSetting.create(name: 'test', value: 'test', value_type: 'string')
    assert_kind_of String, SiteSetting['test']
  end

  test 'integer values should be correctly typed' do
    SiteSetting.create(name: 'test', value: '23', value_type: 'integer')
    assert_kind_of Integer, SiteSetting['test']
  end

  test 'float values should be correctly typed' do
    SiteSetting.create(name: 'test', value: '23.95', value_type: 'float')
    assert_kind_of Float, SiteSetting['test']
  end

  test 'boolean values should be correctly typed' do
    SiteSetting.create(name: 'test', value: 'true', value_type: 'boolean')
    value = SiteSetting['test']
    assert [TrueClass, FalseClass].include?(value.class),
           "Expected #{mu_pp(value)} to be a kind of boolean, not #{value.class}"
  end

  test 'JSON values should be correctly typed' do
    SiteSetting.create(name: 'test', value: '{"data": [1, 2, 3]}', value_type: 'json')
    value = SiteSetting['test']
    assert_kind_of Hash, value
    assert_equal 1, value.keys.size
    assert_kind_of Array, value['data']
    assert_equal 3, value['data'].size
  end

  test 'community settings are in the default scope' do
    SiteSetting.create(community_id: RequestContext.community, name: 'test', value: 'true', value_type: 'string')
    assert SiteSetting.exists?(name: 'test')
  end

  test 'global settings are in the default scope' do
    SiteSetting.create(community_id: nil, name: 'test', value: 'true', value_type: 'string')
    assert SiteSetting.exists?(name: 'test')
  end

  test 'external community settings are not in the default scope' do
    other_community = Community.create(host: 'other', name: 'other')
    SiteSetting.create(community_id: other_community, name: 'test', value: 'true', value_type: 'string')
    assert SiteSetting.exists?(name: 'test')
  end

  test 'community setting takes precedence over global setting' do
    setting1 = SiteSetting.create(community_id: RequestContext.community, name: 'test', value: 'foo', value_type: 'string')
    SiteSetting.create(community_id: nil, name: 'test', value: 'bar', value_type: 'string')
    assert_equal SiteSetting.where(name: 'test').first, setting1
  end

  test 'type predicates should correctly check the setting\'s value type' do
    [:array, :boolean, :float, :integer, :string, :text].each do |method|
      site_settings.each do |setting|
        assert_equal setting.value_type == method.to_s, setting.send("#{method}?")
      end
    end
  end

  test 'numeric? should correctly check if the setting\'s value is numeric' do
    assert site_settings(:int).numeric?
    assert site_settings(:float).numeric?
    assert_not site_settings(:string).numeric?
    assert_not site_settings(:text).numeric?
  end
end

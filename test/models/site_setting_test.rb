require 'test_helper'

class SiteSettingTest < ActiveSupport::TestCase
  test "string values should be correctly typed" do
    SiteSetting.create(name: 'test', value: 'test', value_type: 'string')
    assert_kind_of String, SiteSetting['test']
  end

  test "integer values should be correctly typed" do
    SiteSetting.create(name: 'test', value: '23', value_type: 'integer')
    assert_kind_of Integer, SiteSetting['test']
  end

  test "float values should be correctly typed" do
    SiteSetting.create(name: 'test', value: '23.95', value_type: 'float')
    assert_kind_of Float, SiteSetting['test']
  end

  test "boolean values should be correctly typed" do
    SiteSetting.create(name: 'test', value: 'true', value_type: 'boolean')
    value = SiteSetting['test']
    assert [TrueClass, FalseClass].include?(value.class),
           "Expected #{mu_pp(value)} to be a kind of boolean, not #{value.class}"
  end

  test "JSON values should be correctly typed" do
    SiteSetting.create(name: 'test', value: '{"data": [1, 2, 3]}', value_type: 'json')
    value = SiteSetting['test']
    assert_kind_of Hash, value
    assert_equal 1, value.keys.size
    assert_kind_of Array, value['data']
    assert_equal 3, value['data'].size
  end
end

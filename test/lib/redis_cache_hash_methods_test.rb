require 'test_helper'

class RedisCacheHashMethodsTest < ActiveSupport::TestCase
  test 'redis cache hash methods' do
    assert_nil Rails.cache.read('test_hash')
    assert_equal 1, Rails.cache.hset('test_hash', 'key', 'value')
    assert_equal 'value', Rails.cache.hget('test_hash', 'key')
    assert_equal 'OK', Rails.cache.hmset('test_hash', { 'key2' => 'value2', 'key3' => 'value3' })
    assert_equal({ 'key' => 'value', 'key2' => 'value2', 'key3' => 'value3' },
                 Rails.cache.hmget('test_hash', 'key', 'key2', 'key3'))
    assert_equal({ 'key' => 'value', 'key2' => 'value2', 'key3' => 'value3' },
                 Rails.cache.hgetall('test_hash'))
    assert_equal 1, Rails.cache.hdel('test_hash', 'key3')
    assert_equal 1, Rails.cache.hdel('test_hash')
    assert_nil Rails.cache.read('test_hash')
  end

  test 'rejects calls on unimplemented caches' do
    cache = QPixel::NamespacedEnvCache.new(ActiveSupport::Cache::MemoryStore.new)
    assert_raises NotImplementedError do
      cache.hgetall('test_hash')
    end
  end
end

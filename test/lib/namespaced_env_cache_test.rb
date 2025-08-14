require 'test_helper'

class NamespacedEnvCacheTest < ActiveSupport::TestCase
  setup :new_cache_store

  test 'write_collection/read_collection' do
    collection = Post.where(user: users(:standard_user))
    assert_nothing_raised do
      @cache.write_collection('test_posts_cache', collection)
    end
    data = @cache.read_collection('test_posts_cache')
    assert_not_nil data
    original_ids = collection.map(&:id)
    cached_ids = data.map(&:id)
    cached_ids.each do |cached|
      assert_includes original_ids, cached
    end
  end

  test 'fetch_collection' do
    data = assert_nothing_raised do
      @cache.fetch_collection('test_posts_cache') do
        Post.where(user: users(:standard_user))
      end
    end
    assert_not_nil data
  end

  test 'fetch_collection on subsequent fetches' do
    @cache.fetch_collection('test_posts_cache') do
      Post.where(user: users(:standard_user))
    end
    data = assert_nothing_raised do
      @cache.fetch_collection('test_posts_cache')
    end
    assert_not_nil data
  end

  test 'fetch_collection raises without block on first call' do
    assert_raises ArgumentError do
      @cache.fetch_collection('test_posts_cache')
    end
  end

  test 'write_collection raises on multiple types' do
    assert_raises TypeError do
      @cache.write_collection('test_posts_cache', [Post.last, User.last])
    end
  end

  test 'normalize_collection should correctly prepare collections for caching' do
    collection = Post.where(user: users(:standard_user))
    normalized = QPixel::NamespacedEnvCache.normalize_collection(collection)
    assert_equal Post.name, normalized.shift
    assert(collection.to_a.all? { |post| normalized.include?(post.id) })
  end

  private

  def new_cache_store
    @cache = QPixel::NamespacedEnvCache.new(ActiveSupport::Cache::MemoryStore.new)
  end
end

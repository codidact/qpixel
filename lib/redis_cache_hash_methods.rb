module QPixel
  ##
  # Class for inclusion in a +RedisCacheStore+ or +NamespacedEnvCache+ to add Redis hash methods.
  # If the class is not a +RedisCacheStore+ or +NamespacedEnvCache+, these methods will still be added but will
  # raise at runtime. The cache implementation must be using +ConnectionPool+.
  module RedisCacheHashMethods
    ##
    # Set a hash value.
    # @param hash_key [String] The name of the hash
    # @param key [String] The key within the hash
    # @param value [String] The key's value
    # @return [Integer] The number of keys that were added to the hash
    def hset(hash_key, key, value)
      with_redis do |rd|
        rd.hset hash_key, key, value
      end
    end

    ##
    # Set multiple hash values.
    # @param hash_key [String] The name of the hash
    # @param data [Hash] Keys and values to add to the hash
    # @return [String] 'OK'
    def hmset(hash_key, data)
      with_redis do |rd|
        rd.hmset hash_key, data.to_a.flatten
      end
    end

    ##
    # Get a hash value.
    # @param hash_key [String] The name of the hash
    # @param key [String] The key within the hash
    # @return [String] The key's value
    def hget(hash_key, key)
      with_redis do |rd|
        rd.hget hash_key, key
      end
    end

    ##
    # Get multiple hash values.
    # @param hash_key [String] The name of the hash
    # @param *keys [String] Keys within the hash to retrieve
    # @return [Hash] Keys and values from the hash
    def hmget(hash_key, *keys)
      with_redis do |rd|
        values = rd.hmget hash_key, *keys
        keys.zip(values).to_h
      end
    end

    ##
    # Get all hash values.
    # @param hash_key [String] The name of the hash
    # @return [Hash] The hash's values
    def hgetall(hash_key)
      with_redis do |rd|
        rd.hgetall hash_key
      end
    end

    ##
    # Delete a hash value, or the entire hash.
    # @param hash_key [String] The name of the hash
    # @param *keys [String] Keys within the hash to delete. If none are provided, the entire hash is deleted.
    # @return [Integer] The number of keys that were removed from the hash
    def hdel(hash_key, *keys)
      with_redis do |rd|
        if keys.size.zero?
          rd.del hash_key
        else
          rd.hdel hash_key, *keys
        end
      end
    end

    private

    ##
    # Check a connection out of the connection pool and provides it to the block to run Redis commands.
    # @yield [Redis::Client]
    def with_redis
      reject_unless_redis_cache!
      redis_cache_store = ActiveSupport::Cache::RedisCacheStore
      redis_cache = is_a?(redis_cache_store) ? self : underlying
      redis_cache.redis.with do |rd|
        yield rd
      end
    end

    ##
    # Raises an error unless the current class is a +RedisCacheStore+, or is a +NamespacedEnvCache+ that is backed by
    # a +RedisCacheStore+.
    # @raise [NotImplementedError]
    def reject_unless_redis_cache!
      redis_cache_store = ActiveSupport::Cache::RedisCacheStore
      unless is_a?(redis_cache_store) || (respond_to?(:underlying) && underlying.is_a?(redis_cache_store))
        raise NotImplementedError, "This cache implementation is not backed by Redis and cannot use Hash methods."
      end
    end
  end
end
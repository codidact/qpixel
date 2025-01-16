module QPixel
  class NamespacedEnvCache < ActiveSupport::Cache::Store
    def initialize(underlying)
      @underlying = underlying
      @getters = {}
    end

    # These methods need the cache key name updating before we pass it to the underlying cache.
    [:decrement, :delete, :exist?, :fetch, :increment, :read, :write, :delete_matched].each do |method|
      define_method method do |name, *args, **opts, &block|
        include_community = opts.delete(:include_community)
        @underlying.send(method, construct_ns_key(name, include_community: include_community),
                         *args, **opts, &block)
      end
    end

    # These methods need a hash of cache keys updating before we pass it to the underlying cache.
    [:write_multi].each do |method|
      define_method method do |hash, *args, **opts, &block|
        include_community = opts.delete(:include_community)
        hash = hash.map { |k, v| [construct_ns_key(k, include_community: include_community), v] }.to_h
        @underlying.send(method, hash, *args, **opts, &block)
      end
    end

    # These methods can be passed straight-through to the underlying cache.
    [:cleanup, :clear, :key_matcher, :mute, :silence!].each do |method|
      define_method method do |*args, **opts, &block|
        @underlying.send(method, *args, **opts, &block)
      end
    end

    def read_multi(*keys, **opts)
      include_community = opts.delete(:include_community)
      keys = keys.map { |k| [construct_ns_key(k, include_community: include_community), k] }.to_h
      results = @underlying.read_multi(*keys.keys, **opts)
      results.map { |k, v| [keys[k], v] }.to_h
    end

    def fetch_multi(*keys, **opts, &block)
      include_community = opts.delete(:include_community)
      keys = keys.map { |k| construct_ns_key(k, include_community: include_community) }
      @underlying.fetch_multi(*keys, **opts, &block)
    end

    def persistent(name, **opts, &block)
      namespaced = construct_ns_key(name, include_community: false)
      if block_given?
        @getters[namespaced] = block
      end

      if opts && opts[:clear] == true
        @underlying.delete namespaced
      end

      value = @underlying.read namespaced
      if value.nil?
        if @getters.include? namespaced
          value = @getters[namespaced].call
          @underlying.write namespaced, value
          value
        else
          raise NotImplementedError, 'No config value was available and no block was given'
        end
      else
        value
      end
    end

    # We have to statically report that we support cache versioning even though this depends on the underlying class.
    # However, this is not really a problem since all cache stores provided by activesupport support the feature and
    # we only use the redis cache (by activesupport) for QPixel.
    def self.supports_cache_versioning?
      true
    end

    private

    def construct_ns_key(key, include_community: true)
      c_id = RequestContext.community_id if include_community
      "#{Rails.env}://#{[c_id, key].compact.join('/')}"
    end
  end
end

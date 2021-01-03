module QPixel
  class NamespacedEnvCache < ActiveSupport::Cache::Store
    def initialize(underlying)
      @underlying = underlying
      @getters = {}
    end

    # These methods need the cache key name updating before we pass it to the underlying cache.
    [:decrement, :delete, :exist?, :fetch, :increment, :read, :write].each do |method|
      define_method method do |name, *args, **opts, &block|
        @underlying.send(method, construct_ns_key(name), *args, **opts, &block)
      end
    end

    # These methods need a hash of cache keys updating before we pass it to the underlying cache.
    [:fetch_multi, :read_multi, :write_multi].each do |method|
      define_method method do |hash, *args, **opts, &block|
        hash = hash.map { |k, v| [construct_ns_key(k), v] }.to_h
        @underlying.send(method, hash, *args, **opts, &block)
      end
    end

    # These methods can be passed straight-through to the underlying cache.
    [:cleanup, :clear, :key_matcher, :mute, :silence!].each do |method|
      define_method method do |*args, **opts, &block|
        @underlying.send(method, *args, **opts, &block)
      end
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

    # This can't easily be supported, matchers are hard to update for a new name.
    def delete_matched
      raise NotImplementedError, "#{self.class} does not support delete_matched"
    end

    private
    def construct_ns_key(key, include_community: true)
      c_id = RequestContext.community_id if include_community
      "#{Rails.env}://#{[c_id, key].compact.join('/')}"
    end
  end
end

Rails.cache = QPixel::NamespacedEnvCache.new(Rails.cache)

module QPixel
  class NamespacedEnvCache < ActiveSupport::Cache::Store
    def initialize(underlying)
      @underlying = underlying
      @getters = {}
    end

    def include_community(opts)
      include = opts.delete(:include_community)
      include.nil? ? true : include
    end

    # These methods need the cache key name updating before we pass it to the underlying cache.
    [:decrement, :delete, :exist?, :fetch, :increment, :read, :write, :delete_matched].each do |method|
      define_method method do |name, *args, **opts, &block|
        include_community = include_community(opts)
        @underlying.send(method, construct_ns_key(name, include_community: include_community),
                         *args, **opts, &block)
      end
    end

    # These methods need a hash of cache keys updating before we pass it to the underlying cache.
    [:write_multi].each do |method|
      define_method method do |hash, *args, **opts, &block|
        include_community = include_community(opts)
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
      include_community = include_community(opts)
      keys = keys.map { |k| [construct_ns_key(k, include_community: include_community), k] }.to_h
      results = @underlying.read_multi(*keys.keys, **opts)
      results.map { |k, v| [keys[k], v] }.to_h
    end

    def fetch_multi(*keys, **opts, &block)
      include_community = include_community(opts)
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

    ##
    # Cache an ActiveRecord collection. Supports only a basic collection of one type of object. Column selections or
    # joins etc. will NOT be respected when the collection is read back out.
    # @param name [String] cache key name
    # @param value [ActiveRecord::Relation] collection to cache
    # @param opts [Hash] options hash - any unlisted options will be passed to the underlying cache
    # @option opts [Boolean] :include_community whether to include the community ID in the cache key
    def write_collection(name, value, **opts)
      types = value.map(&:class).uniq
      if types.size > 1
        raise TypeError, "Can't cache more than one type of object via write_collection"
      end

      data = [types[0].to_s, *value.map(&:id)]
      namespaced = construct_ns_key(name, include_community: include_community(opts))
      @underlying.write(namespaced, data, **opts)
    end

    ##
    # Read an ActiveRecord collection from cache. Returns a basic collection of the records that were cached, with
    # no selects or joins applied.
    # @param name [String] cache key name
    # @param opts [Hash] options hash - any unlisted options will be passed to the underlying cache
    # @options opts [Boolean] :include_community whether to include the community ID in the cache key
    def read_collection(name, **opts)
      namespaced = construct_ns_key(name, include_community: include_community(opts))
      data = @underlying.read(namespaced, **opts)
      return nil if data.nil?
      type = data.slice!(0)
      begin
        type.constantize.where(id: data)
      rescue NameError
        delete(name)
        nil
      end
    end

    ##
    # Fetch an ActiveRecord collection from cache if it is present, otherwise cache the value returned by +block+.
    # @param name [String] cache key name
    # @param opts [Hash] options hash - any unlisted options will be passed to the underlying cache
    # @option opts [Boolean] :include_community whether to include the community ID in the cache key
    # @yieldreturn [ActiveRecord::Relation]
    def fetch_collection(name, **opts, &block)
      existing = if exist?(name, include_community: include_community(opts))
                   read_collection(name, **opts)
                 end
      if existing.nil?
        unless block_given?
          raise ArgumentError, "Can't fetch collection without a block given"
        end
        data = block.call
        write_collection(name, data, **opts)
        data
      else
        existing
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
      key = expanded_key(key)
      c_id = RequestContext.community_id if include_community
      "#{Rails.env}://#{[c_id, key].compact.join('/')}"
    end
  end
end

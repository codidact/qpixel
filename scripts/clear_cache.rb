Rails.cache.delete_matched 'network/*'
RequestContext.redis.keys('*pinned_links').each do |key|
  RequestContext.redis.del(key)
end

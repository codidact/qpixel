redis = RequestContext.redis

redis.scan_each(:match => "saved_post.*.*.tags") do |key| 
  redis.srem?(key, '')
end
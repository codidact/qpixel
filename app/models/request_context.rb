class RequestContext
  class << self
    def fetch
      Thread.current[:context] || clear!
    end

    def clear!
      Thread.current[:context] = {}
    end

    def redis
      if $redis
        $redis
      else
        processed = ERB.new(File.read(Rails.root.join('config', 'database.yml'))).result(binding)
        $redis ||= Redis.new(YAML.load(processed)["redis_#{Rails.env}"])
      end
    rescue NoMethodError
      raise LoadError, "You don't appear to have any Redis config in config/database.yml"
    end

    %i[user community].each do |field|
      define_method "#{field}=" do |value|
        fetch[field] = value
      end

      define_method field do
        fetch[field]
      end

      define_method "#{field}_id" do
        fetch[field]&.id
      end
    end
  end
end

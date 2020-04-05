class RequestContext
  class << self
    def fetch
      Thread.current[:context] || clear!
    end

    def clear!
      Thread.current[:context] = {}
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

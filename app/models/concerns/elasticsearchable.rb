# Adds elastic search support to the given model
#
# We use a mocking approach to allow elasticsearch to be enabled and disabled without server restart.
module Elasticsearchable
  extend ActiveSupport::Concern

  # Mock for elasticsearch when it is not enabled.
  class ElasticsearchMock
    def client
      self
    end

    def method_missing(_name); end
  end

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    # Use the Rails env in the index name to prevent issues of test indices overriding development/production indices
    index_name "#{Rails.env}_#{model_name.collection.gsub(%r{/}, '-')}"

    # Override elasticsearch class method such that we can mock it in case elasticsearch is disabled
    def self.__elasticsearch__(&block)
      if SiteSetting['ElasticsearchEnabled']
        @__elasticsearch__ ||= Elasticsearch::Model::Proxy::ClassMethodsProxy.new(self)
        @__elasticsearch__.instance_eval(&block) if block_given?
        @__elasticsearch__
      else
        ElasticsearchMock.new
      end
    end

    # Override elasticsearch instance method such that we can mock it in case elasticsearch is disabled
    def __elasticsearch__(&block)
      if SiteSetting['ElasticsearchEnabled']
        @__elasticsearch__ ||= Elasticsearch::Model::Proxy::InstanceMethodsProxy.new(self)
        @__elasticsearch__.instance_eval(&block) if block_given?
        @__elasticsearch__
      else
        ElasticsearchMock.new
      end
    end
  end
end

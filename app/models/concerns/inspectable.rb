module Inspectable
  extend ActiveSupport::Concern
  included do
    def inspect
      "##{self.class.name} #{attributes.compact.map { |k, v| "#{k}: #{v}" }.join(', ')}>"
    end
  end
end

module Identity
  extend ActiveSupport::Concern

  included do
    # Is this record the same as a given other record?
    # @param other [Class, nil] record to compare with
    # @return [Boolean] check result
    def same_as?(other)
      instance_of?(other.class) && id == other.id
    end
  end
end

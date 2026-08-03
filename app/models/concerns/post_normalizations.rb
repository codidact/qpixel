module PostNormalizations
  extend ActiveSupport::Concern

  included do
    normalizes :before_state, :after_state, with: -> text { normalize_newlines(text) }
  end

  class_methods do
    def normalize_newlines(text)
      text.encode(text.encoding, universal_newline: true).strip
    end
  end
end

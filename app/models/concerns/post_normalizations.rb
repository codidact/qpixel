module PostNormalizations
  extend ActiveSupport::Concern

  class_methods do
    def normalize_newlines(text)
      text.encode(text.encoding, universal_newline: true).strip
    end
  end
end

module PostNormalizations
  extend ActiveSupport::Concern

  def normalize_newlines(text)
    text.encode(text.encoding, universal_newline: true).strip
  end
end

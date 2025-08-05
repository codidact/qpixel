module SubscriptionsHelper
  # Generate <select> options for available subscription frequences
  # @return [Array(String, String)>]
  def frequency_choice
    [
      ['Every day', 1],
      ['Every week', 7],
      ['Every month', 30],
      ['Every quarter', 90]
    ]
  end
end

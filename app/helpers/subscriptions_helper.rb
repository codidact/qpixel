module SubscriptionsHelper
  # Generates <select> options for available subscription frequences
  # @return [Array(String, String)]
  def frequency_choice
    [
      ['Every day', 1],
      ['Every week', 7],
      ['Every month', 30],
      ['Every quarter', 90]
    ]
  end

  # Generates <select> options for available subscription types for a given user
  # @param user [User] user to perform access control checks for
  # @return [Array(String, String)]
  def type_choice_for(user)
    Subscription.types_accessible_to(user)
                .map { |type| [phrase_for(type).capitalize, type] }
  end
end

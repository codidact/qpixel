module SubscriptionsHelper
  # Generates <select> options for available subscription frequences
  # @return [Array(String, Integer)]
  def frequency_choice
    [
      ['Every day', 1],
      ['Every week', 7],
      ['Every month', 30],
      ['Every quarter', 90]
    ]
  end

  # Gets human-readable representation of a given subscription type
  # @param type [String] subscription type
  # @return [String]
  def phrase_for(type)
    phrase_map = {
      all: 'all new questions',
      tag: 'new questions with the tag',
      user: 'new questions by the user',
      interesting: 'new questions classed as interesting',
      category: 'new questions in the category',
      moderators:  'announcements and newsletters for moderators'
    }

    phrase_map[type.to_sym] || 'nothing, apparently. How did you get here, again?'
  end

  # Generates <select> options for available subscription types for a given user
  # @param user [User] user to perform access control checks for
  # @return [Array(String, String)]
  def type_choice_for(user)
    Subscription.types_accessible_to(user)
                .map { |type| [phrase_for(type).capitalize, type] }
  end
end

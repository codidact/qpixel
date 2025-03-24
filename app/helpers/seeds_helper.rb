module SeedsHelper
  def update_from_seeds(type, unique_key, value_attribute)
    data = YAML.load_file(Rails.root.join("db/seeds/#{type}.yml"))
    cls = type.to_s.singularize.classify.constantize
    data.each do |seed|
      cls.unscoped.where(unique_key => seed[unique_key.to_s]).update(value_attribute => seed[value_attribute.to_s])
    end
  end

  # Prioritize models such that dependent ones are created after the specified ones
  # @param types [Array<Class>] list of model classes
  # @param files [Array<String>] list of seed file paths
  # @return [Hash<String, Class>]
  def self.prioritize(types, files)
    priority = [PostType, CloseReason, License, TagSet, PostHistoryType, User, Ability, CommunityUser, Filter]

    files.zip(types).to_h.sort do |a, b|
      (priority.index(a.second) || 999) <=> (priority.index(b.second) || 999)
    end.to_h
  end
end

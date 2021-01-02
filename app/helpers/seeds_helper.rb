module SeedsHelper
  def update_from_seeds(type, unique_key, value_attribute)
    data = YAML.load_file(Rails.root.join("db/seeds/#{type}.yml"))
    cls = type.to_s.singularize.classify.constantize
    data.each do |seed|
      cls.unscoped.where(unique_key => seed[unique_key.to_s]).update(value_attribute => seed[value_attribute.to_s])
    end
  end
end

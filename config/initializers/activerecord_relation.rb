class ActiveRecord::Relation
  # Preload one level a chained association whose name is specified in attribute.
  def preload_chain(attribute, collection: nil)
    preloader = ActiveRecord::Associations::Preloader.new
    preloader.preload(collection || records, attribute.to_sym)
    self
  end

  # Preload all levels of a chained association specified in attribute. Will cause infinite loops if there are cycles.
  def deep_preload_chain(attribute, collection: nil)
    return if (collection || records).empty?
    preload_chain(attribute, collection: collection)
    deep_preload_chain(attribute, collection: (collection || records).select(&attribute.to_sym).map(&attribute.to_sym))
    self
  end

  # Preload one level of a chained association on a table referenced by the current table.
  def preload_reference_chain(**reference_attribs)
    reference_attribs.each do |t, a|
      preload_chain(a, collection: records.map { |r| r.public_send(t.to_sym) })
    end
    self
  end

  # Preload all levels (including infinite loops) of a chained association on a referenced table.
  def deep_preload_reference_chain(**reference_attribs)
    reference_attribs.each do |t, a|
      deep_preload_chain(a, collection: records.map { |r| r.public_send(t.to_sym) })
    end
    self
  end
end
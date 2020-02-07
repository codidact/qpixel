# frozen_string_literal: true

Rails.application.eager_load!

RequestContext.community = Community.new(id: 1)

%w(communities post_history_types post_types site_settings users community_users posts privileges).each do |table_name|
  f = Rails.root.join("db/seeds/#{table_name}.yml").to_s
  type = table_name.classify.constantize
  begin
    processed = ERB.new(File.read(f)).result(binding)
    data = YAML.load(processed)
    created = 0
    skipped = 0
    data.each do |rd|
      obj = type.create rd
      if obj.errors.any?
        skipped += 1
      else
        created += 1
      end
    end
    puts "#{type}: Created #{created}, skipped #{skipped}" unless Rails.env.test?
  rescue StandardError => e
    puts "Got error #{e}. Continuing..."
  end
end

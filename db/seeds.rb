# frozen_string_literal: true

Rails.application.eager_load!

if ENV['SEEDS'].present?
  find_glob = "db/seeds/**/#{ENV['SEEDS'].underscore}.yml"
else
  find_glob = 'db/seeds/**/*.yml'
end

Dir.glob(Rails.root.join(find_glob)).each do |f|
  basename = Pathname.new(f).relative_path_from(Pathname.new(Rails.root.join('db/seeds'))).to_s
  type = basename.gsub('.yml', '').singularize.classify.constantize
  begin
    processed = ERB.new(File.read(f)).result(binding)
    data = YAML.load(processed)
    created = 0
    skipped = 0
    data.each do |seed|
      seed.each do |attr, value|
        if value.is_a?(String) && value.start_with?("$FILE ")
          seed[attr] = File.read(Rails.root.join('db/seeds', value.gsub("$FILE ", '')))
        end
      end

      seeds = if type.column_names.include? 'community_id'
                # if model includes a community_id, create the seed for every community
                Community.all.map { |c| seed.deep_symbolize_keys.merge(community_id: c.id) }
              else
                # otherwise, no need to worry, just create it
                [seed]
              end
      objs = type.create seeds
      skipped += objs.select { |o| o.errors.any? }.size
      created += objs.select { |o| !o.errors.any? }.size
    end
    puts "#{type}: Created #{created}, skipped #{skipped}" unless Rails.env.test?
  rescue StandardError => e
    puts "Got error #{e}. Continuing..."
  end
end

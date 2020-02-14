# frozen_string_literal: true

Rails.application.eager_load!

Dir.glob(Rails.root.join('db/seeds/**/*.yml')).each do |f|
  basename = Pathname.new(f).relative_path_from(Pathname.new(Rails.root.join('db/seeds'))).to_s
  type = basename.gsub('.yml', '').singularize.classify.constantize
  begin
    processed = ERB.new(File.read(f)).result(binding)
    data = YAML.load(processed)
    created = 0
    skipped = 0
    data.each do |seed|
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

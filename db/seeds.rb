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
    updated = 0
    data.each do |seed|
      seed.each do |attr, value|
        if value.is_a?(String) && value.start_with?("$FILE ")
          seed[attr] = File.read(Rails.root.join('db/seeds', value.gsub("$FILE ", '')))
        end
      end

      if type == Post && ENV['UPDATE_POSTS'] == 'true'
        puts "Running full Posts update..."

        seed['body'] = ApplicationController.helpers.render_markdown(seed['body_markdown'])
        Community.all.each do |c|
          RequestContext.community = c
          post = Post.find_by doc_slug: seed['doc_slug']
          if post.present? && PostHistory.where(post: post).count <= 1
            # post exists, still original version: update post
            post.update(seed.merge('community_id' => c.id))
            updated += 1
          elsif post.nil?
            # post doesn't exist: create post
            Post.create seed.merge('community_id' => c.id)
            created += 1
          else
            # post exists, versions diverged: skip
            skipped += 1
          end
        end
      else
        seeds = if type.column_names.include?('community_id') && !seed.include?('community_id')
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
    end
    unless Rails.env.test?
      puts "#{type}: Created #{created}, #{updated > 0 ? "updated #{updated}, " : ''}skipped #{skipped}"
    end
  rescue StandardError => e
    puts "Got error #{e}. Continuing..."
  end
end

Post.where(community_id: nil).destroy_all

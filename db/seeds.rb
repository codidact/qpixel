# frozen_string_literal: true

Rails.application.eager_load!

if ENV['SEEDS'].present?
  find_glob = "db/seeds/**/#{ENV['SEEDS'].underscore}.yml"
else
  find_glob = 'db/seeds/**/*.yml'
end

# Get all seed files and determine their model types
files = Dir.glob(Rails.root.join(find_glob))
types = files.map do |f|
  basename = Pathname.new(f).relative_path_from(Pathname.new(Rails.root.join('db/seeds'))).to_s
  basename.gsub('.yml', '').singularize.classify.constantize
end

sorted = SeedsHelper.prioritize(types, files)

def expand_communities(type, seed)
  if type.column_names.include?('community_id') && !seed.include?('community_id')
    # if model includes a community_id, create the seed for every community
    Community.all.map { |c| seed.deep_symbolize_keys.merge(community_id: c.id) }
  else
    # otherwise, no need to worry, just create it
    [seed]
  end
end

def expand_ids(type, seeds)
  # Transform all _id relations into the actual rails objects to pass validations
  seeds.map do |seed|
    columns = type.column_names.select { |name| name.match(/^.*_id$/) }
    new_seed = seed.deep_symbolize_keys
    columns.each do |column|
      begin
        column_type_name = column.chomp('_id')
        column_type = column_type_name.classify.constantize
        new_seed = new_seed.except(column.to_sym)
                           .merge(column_type_name.to_sym => column_type.unscoped.find(seed[column.to_sym]))
      rescue StandardError
        # Either the type does not exist or the value specified as the id is not valid, ignore.
        next
      end
    end
    new_seed
  end
end

def create_objects(type, seed)
  seeds = expand_communities(type, seed)
  seeds = expand_ids(type, seeds)

  # Actually create the objects and count successes
  objs = type.create seeds

  skipped = objs.select { |o| o.errors.any? }.size
  created = objs.select { |o| !o.errors.any? }.size

  [created, skipped]
end

def ensure_system_user_abilities
  system_users = CommunityUser.unscoped.where(user_id: -1)

  system_users.each do |su|
    abilities = Ability.unscoped
      .where(internal_id: ['everyone', 'mod', 'unrestricted'])
      .where(community_id: su.community_id)

    user_abilities = UserAbility.unscoped.where(community_user_id: su.id)

    abilities.each do |ab|
      unless user_abilities.any? { |ua| ua.ability_id == ab.id }
        UserAbility.create community_user_id: su.id, ability: ab
      end
    rescue => e
      puts "#{type}: failed to add \"#{ab.name}\" to system user \"#{su.id}\" on \"#{su.community.name}\""
      puts e
    end
  end
end

sorted.each do |f, type|
  begin
    processed = ERB.new(File.read(f)).result(binding)
    data = YAML.load(processed)
    created = 0
    errored = 0
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

        system_usr = User.find(-1)

        Community.all.each do |c|
          RequestContext.community = c
          post = Post.find_by doc_slug: seed['doc_slug']
          if post.present? && PostHistory.where(post: post)
                                         .where.not(post_history_type:
                                                      PostHistoryType.find_by(name: 'initial_revision'))
                                         .count.zero?

            # post exists, still original version: update post
            post.update(seed.merge('community_id' => c.id))

            no_initial = PostHistory.where(post: post)
                       .where(post_history_type: PostHistoryType.find_by(name: 'initial_revision'))
                       .count.zero?

            if no_initial
              puts "[#{c.name}:#{seed['doc_slug']}] missing initial revision, creating..."
              PostHistory.initial_revision(post, system_usr)
            end

            updated += 1
          elsif post.nil?
            # post doesn't exist: create post
            status = Post.create seed.merge('community_id' => c.id, 'user' => system_usr)

            if status.errors.size
              status.errors.full_messages.each do |msg|
                puts "[#{c.name}:#{seed['doc_slug']}] invalid: #{msg}"
              end

              errored += 1
            else
              created += 1
            end
          else
            # post exists, versions diverged: skip
            skipped += 1
          end
        end
      else
        new_created, new_skipped = create_objects(type, seed)
        created += new_created
        skipped += new_skipped

        if type == CommunityUser
          ensure_system_user_abilities
        end
      end
    end
    unless Rails.env.test?
      puts "#{type}: errored #{errored}, created #{created}, #{updated > 0 ? "updated #{updated}, " : ''}skipped #{skipped}"
    end
  rescue StandardError => e
    puts "Got error #{e}. Continuing..."
  end
end

Post.where(community_id: nil).destroy_all

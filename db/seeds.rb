# frozen_string_literal: true

Rails.application.eager_load!

files = SeedsHelper.files(ENV.fetch('SEEDS', nil))
types = SeedsHelper.types(files)
sorted = SeedsHelper.prioritize(types, files)

should_update_posts = ENV['UPDATE_POSTS'] == 'true'

Stats = Struct.new('Stats', :created, :updated, :errored, :skipped) do |struct|
  struct.members.each do |member|
    define_method "add_#{member}" do |num|
      self[member] += num
    end
  end

  def <<(other)
    members.each do |member|
      send("add_#{member}", other[member])
    end
  end

  def print
    members.map { |m| self[m]&.positive? ? "#{m} #{self[m]}" : nil }
           .compact
           .join(', ')
  end
end

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
      column_type_name = column.chomp('_id')
      column_type = column_type_name.classify.constantize
      new_seed = new_seed.except(column.to_sym)
                         .merge(column_type_name.to_sym => column_type.unscoped.find(seed[column.to_sym]))
    rescue StandardError
      # Either the type does not exist or the value specified as the id is not valid, ignore.
      next
    end
    new_seed
  end
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

def init_seed(type, seed)
  seed.each do |attr, value|
    if value.is_a?(String) && value.start_with?('$FILE ')
      seed[attr] = File.read(Rails.root.join('db/seeds', value.gsub('$FILE ', '')))
    end
  end

  if type == Post
    seed['body'] = render_seed(seed)
  end
end

def render_seed(seed)
  ApplicationController.helpers.render_markdown(seed['body_markdown'])
end

# TODO: make it the Post model's predicate (and add association):
def not_edited?(post)
  PostHistory.where(post: post)
             .where.not(post_history_type: PostHistoryType.find_by(name: 'initial_revision'))
             .none?
end

def no_initial_revision?(post)
  PostHistory.where(post: post)
             .where(post_history_type: PostHistoryType.find_by(name: 'initial_revision'))
             .none?
end

# @param user [User] user to assign changes to
# @param community [Community] community to create the post on
# @param seed [Hash] initialized seed
# @return [Stats] operation stats
def create_post(user, community, seed)
  stats = Stats.new(0, 0, 0, 0)
  created = Post.create seed.merge('community_id' => community.id, 'user' => user)

  if created.errors.any?
    created.errors.full_messages.each do |msg|
      puts "[#{community.name}:#{seed['doc_slug']}] invalid: #{msg}"
    end

    stats.add_errored(1)
  else
    stats.add_created(1)
  end

  stats
end

# @param user [User] user to assign changes to
# @param community [Community] community the post belongs to
# @param post [Post] post to update
# @param seed [Hash] initialized seed
# @return [Stats] operation stats
def update_post(user, community, post, seed)
  stats = Stats.new(0, 0, 0, 0)
  updated = post.update(seed.merge('community_id' => community.id))

  if no_initial_revision?(post)
    puts "[#{community.name}:#{seed['doc_slug']}] missing initial revision, creating..."
    PostHistory.initial_revision(post, user)
  end

  if updated.errors.any?
    updated.errors.full_messages.each do |msg|
      puts "[#{community.name}:#{seed['doc_slug']}] invalid: #{msg}"
    end

    stats.add_errored(1)
  else
    stats.add_updated(1)
  end

  stats
end

# @return [Stats] operation stats
def seed_objects(type, seed)
  seeds = expand_communities(type, seed)
  seeds = expand_ids(type, seeds)

  # Actually create the objects and count successes
  objs = type.create(seeds)

  skipped = objs.select { |o| o.errors.any? }.size
  created = objs.reject { |o| o.errors.any? }.size

  # Post type cache must be manually cleared \
  # (its mappings need it, but only the controller clears the cache on create)
  if type == PostType
    type.clear_ids_cache
  end

  if type == CommunityUser
    ensure_system_user_abilities
  end

  Stats.new(created, 0, 0, skipped)
end

# @param seed [Hash] initialized seed
# @param update_posts [Boolean] whether to update existing posts
# @return [Stats] operation stats
def seed_posts(seed, update_posts)
  system_usr = User.find(-1)
  stats = Stats.new(0, 0, 0, 0)

  Community.all.each do |community|
    RequestContext.community = community
    post = Post.find_by(doc_slug: seed['doc_slug'])

    if post.present? && update_posts && not_edited?(post)
      stats << update_post(system_usr, community, post, seed)
    elsif post.nil?
      stats << create_post(system_usr, community, seed)
    else
      stats.add_skipped(1)
    end
  end

  stats
end

def seed_community_assets
  Community.all.each do |community|
    RequestContext.community = community
    host = community.host.split('.')[0]

    [:css, :js].each do |ext|
      setting_name = "#{ext.to_s.upcase}Path"
      asset_path = Rails.public_path.join('./assets/community', "#{host}.#{ext}")

      if SiteSetting[setting_name].blank? && File.exist?(asset_path)
        SiteSetting[setting_name] = "/assets/community/#{host}.#{ext}"
      end
    rescue => e
      puts "[#{community.name}] failed to seed asset: #{e.message}"
    end
  end
end

sorted.each do |f, type|
  processed = ERB.new(File.read(f)).result(binding)
  data = YAML.load(processed)
  stats = Stats.new(0, 0, 0, 0)
  data.each do |seed|
    init_seed(type, seed)

    stats << if type == Post
               seed_posts(seed, should_update_posts)
             else
               seed_objects(type, seed)
             end
  end
  unless Rails.env.test?
    puts "#{type}: #{stats.print}"
  end
rescue StandardError => e
  puts "Got error #{e}. Continuing..."
end

Post.where(community_id: nil).destroy_all

seed_community_assets

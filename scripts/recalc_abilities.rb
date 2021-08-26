options = OpenStruct.new

OptionParser.new do |opts|
  opts.banner = "Usage: rails r scripts/recalc_abilities.rb [options]"

  opts.on('-v', '--verbose', 'Run with additional logging') do
    options.verbose = true
  end

  opts.on('-q', '--quiet', 'Run with minimal logging') do
    options.quiet = true
  end
end.parse!

resolved = []
destroy = []
all = AbilityQueue.pending.to_a

all.each do |q|
  begin
    cu = q.community_user
    u = cu&.user

    if cu.nil? || u.nil?
      destroy << q.id
      next
    end

    RequestContext.community = cu.community

    if options.verbose && !options.quiet
      puts "Scope: Community     : #{cu.community.name} (#{cu.community.host})"
      puts "       User          : #{u.username} (#{cu.user_id})"
      puts "       CommunityUser : #{cu.id}"
    elsif !options.verbose && !options.quiet
      puts "Scope: CommunityUser : #{cu.id}"
    end

    cu.recalc_privileges

    # Grant mod ability if mod status is given
    if (cu.is_moderator || cu.is_admin || u.is_global_moderator || u.is_global_admin) && !cu.privilege?('mod')
      cu.grant_privilege('mod')
    end

    resolved << q.id
  rescue => e
    $stderr.puts "  Failed: #{e.class.name}: #{e.message}"
    $stderr.puts e.backtrace
  end
end

AbilityQueue.where(id: resolved).update(completed: true)
AbilityQueue.where(id: destroy).delete_all

unless options.quiet
  puts "Completed, #{resolved.size}/#{all.size} tasks successful, #{destroy.size} tasks invalid"
end
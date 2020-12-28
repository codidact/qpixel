puts "Recalculating the Abilities (Scheduled)"
puts

resolved = []

AbilityQueue.pending.map do |q|
  cu = q.community_user
  puts "Scope: CommunityUser.Id=#{cu.id}"
  RequestContext.community = cu.community
  cu.recalc_privileges

  # Grant mod ability if mod status is given
  if (cu.is_moderator || cu.is_admin || u.is_global_moderator || u.is_global_admin) && !cu.privilege?('mod')
    cu.grant_privilege('mod')
  end
  
  resolved << q.id
  rescue
    puts "  Failed."
end

# Mark resolved queue tasks as completed
AbilityQueue.where(id: resolved).update(completed: true)

puts "---"
puts "Recalculating completed"
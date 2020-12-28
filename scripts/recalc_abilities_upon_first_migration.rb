puts "Recalculating all the Abilities"
puts

User.unscoped.all.map do |u|
  puts "Scope: User.Id=#{u.id}"
  CommunityUser.unscoped.where(user: u).all.map do |cu|
    puts "  Attempt CommunityUser.Id=#{cu.id}"
    RequestContext.community = cu.community
    cu.recalc_privileges

    if (cu.is_moderator || cu.is_admin || u.is_global_moderator || u.is_global_admin) && !cu.privilege?('mod')
      cu.grant_privilege('mod')
    end
  rescue
    puts "    !!! Error recalcing for CommunityUser.Id=#{cu.id}"
  end
  puts "End"
  puts
end

puts "---"
puts "Recalculating completed"

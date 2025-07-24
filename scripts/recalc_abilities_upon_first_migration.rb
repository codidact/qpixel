puts "Recalculating all the Abilities"
puts

User.unscoped.all.map do |u|
  puts "Scope: User.Id=#{u.id}"

  u.community_users.each do |cu|
    puts "  Attempt CommunityUser.Id=#{cu.id}"
    RequestContext.community = cu.community
    cu.recalc_privileges!

    if cu.at_least_moderator? && !cu.privilege?('mod')
      puts "  Granting mod privilege to CommunityUser.Id=#{cu.id}"
      cu.grant_privilege!('mod')
    end

    puts "  Recalc success for CommunityUser.Id=#{cu.id}"
  rescue
    puts "    !!! Error recalcing for CommunityUser.Id=#{cu.id}"
  end
  puts "End"
  puts
end

puts "---"
puts "Recalculating completed"

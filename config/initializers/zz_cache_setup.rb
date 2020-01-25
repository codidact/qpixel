Rails.cache.persistent 'current_commit', clear: true do
  "#{`git rev-parse HEAD`.strip[0..7]} (#{`git log -1 --date=iso --pretty=format:%cd`.strip})"
end

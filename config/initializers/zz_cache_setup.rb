Rails.cache.persistent 'current_commit', clear: true do
  [`git rev-parse HEAD`.strip, `git log -1 --date=iso-strict --pretty=format:%cd`.strip]
end

Rails.cache.persistent 'current_commit', clear: true do
  commit_sha = `git rev-parse HEAD`.strip
  commit_date = `git log -1 --date=iso-strict --pretty=format:%cd`.strip
  [commit_sha, commit_date]
end

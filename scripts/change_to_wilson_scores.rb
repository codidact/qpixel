# First we grab votes so we can populate upvote_count and downvote_count
puts "01: Vote grab"
votes = Vote.unscoped.all.group(:post_id, :vote_type).count

# Format translation
# {[123, 1] => 34, [123, -1] => 43, [124, 1] => 45, [124, -1] => 56} into
# {123 => {1 => 34, -1 => 43}, 124 => {1 => 45, -1 => 56}}
puts "02: Vote translation"
votes = votes.to_a.group_by { |v| v[0][0] }.map { |i, v| [i, v.map { |g| [g[0][1], g[1]] }.to_h] }.to_h

# Generate and execute sanitized update SQL for each post.
progress = ProgressBar.create(title: "03: UPDATEs", total: votes.size, progress_mark: '█')
votes.each do |post_id, vote_counts|
  params = []
  updates = vote_counts.map do |vt, count|
    attrib = { 1 => 'upvote_count', -1 => 'downvote_count' }[vt]
    params << count
    "#{attrib} = ?"
  end
  params << post_id
  sql = "UPDATE posts SET #{updates.join(', ')} WHERE id = ?"
  sanitized = ActiveRecord::Base.sanitize_sql_array([sql, *params])
  ActiveRecord::Base.connection.execute sanitized
  progress.increment
end

# TODO add actual score calculation
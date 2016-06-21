Question.all.each do |q|
  q.score = q.votes.sum(:vote_type)
  q.save!
end

Answer.all.each do |a|
  a.score = a.votes.sum(:vote_type)
  a.save!
end

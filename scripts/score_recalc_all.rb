Question.all.each do |q|
  puts q.id
  q.score = q.votes.sum(:vote_type)
  q.save!
end

Answer.all.each do |a|
  puts a.question.id
  a.score = a.votes.sum(:vote_type)
  a.save!
end

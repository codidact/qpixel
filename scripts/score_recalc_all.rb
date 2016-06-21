Question.all.each do |q|
  puts q.id
  q.score = q.votes.sum(:vote_type)
  q.save!
end

Answer.all.each do |a|
  puts a.question.id if a.question
  a.score = a.votes.sum(:vote_type)
  a.save!
end

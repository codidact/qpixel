# Rep Recalculator
# Recalculates the reputation score for one user, specified by the ID given in the first command line argument.

qu = SiteSetting['QuestionUpVoteRep']
qd = SiteSetting['QuestionDownVoteRep']
au = SiteSetting['AnswerUpVoteRep']
ad = SiteSetting['AnswerDownVoteRep']

users = User.all

users.each do |u|
  u.reputation = 1

  u.questions.each do |p|
    upvotes = p.votes.where(vote_type: 1).count
    downvotes = p.votes.where(vote_type: -1).count
    p.user.reputation += qu * upvotes
    p.user.reputation += qd * downvotes
    puts "Questions: #{upvotes} up, #{downvotes} down => #{qu*upvotes}, #{qd*downvotes} rep"
    p.user.save!
  end

  u.answers.each do |p|
    upvotes = p.votes.where(vote_type: 1).count
    downvotes = p.votes.where(vote_type: -1).count
    p.user.reputation += au * upvotes
    p.user.reputation += ad * downvotes
    puts "Answers: #{upvotes} up, #{downvotes} down => #{au*upvotes}, #{ad*downvotes} rep"
    p.user.save!
  end
end

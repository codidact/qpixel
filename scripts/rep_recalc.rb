# Rep Recalculator
# Recalculates the reputation score for one user, specified by the ID given in the first command line argument.

def get_setting(name)
  begin
    return SiteSetting.find_by_name(name).value
  rescue
    return nil
  end
end

qu = get_setting('QuestionUpVoteRep').to_i
qd = get_setting('QuestionDownVoteRep').to_i
au = get_setting('AnswerUpVoteRep').to_i
ad = get_setting('AnswerDownVoteRep').to_i

u = User.find ARGV[0]

u.questions.each do |p|
  upvotes = p.votes.where(:vote_type => 0).count
  downvotes = p.votes.where(:vote_type => 1).count
  p.user.reputation += qu * upvotes
  p.user.reputation += qd * downvotes
  puts "#{upvotes}:#{downvotes}, #{qu*upvotes}:#{qd*downvotes}"
  p.user.save!
end

u.answers.each do |p|
  upvotes = p.votes.where(:vote_type => 0).count
  downvotes = p.votes.where(:vote_type => 1).count
  p.user.reputation += au * upvotes
  p.user.reputation += ad * downvotes
  puts "#{upvotes}:#{downvotes}, #{au*upvotes}:#{ad*downvotes}"
  p.user.save!
end

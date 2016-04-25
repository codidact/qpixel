# Post Score Recalculator
# Recalculates the score for one post, specified by the ID given in the first command line parameter.
# Pass the post type ("Answer" or "Question") as the second parameter.

def get_post
  begin
    if ARGV[1].downcase == "answer"
      return Answer.find ARGV[0]
    elsif ARGV[1].downcase == "question"
      return Question.find ARGV[0]
    else
      puts "unrecognized post type"
    end
  rescue
    puts "error"
  end
end

post = get_post

upvotes = post.votes.where(:vote_type => 0).count
downvotes = post.votes.where(:vote_type => 1).count

post.score = upvotes - downvotes
post.save!

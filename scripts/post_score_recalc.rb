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
post.score = post.votes.sum(:vote_type)
post.save!

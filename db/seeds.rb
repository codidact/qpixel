# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

default_settings = [
  [ 'SiteName', 'QPixel' ],
  [ 'SiteLogoPath', '/assets/logo.png' ],
  [ 'QuestionUpVoteRep', '5' ],
  [ 'QuestionDownVoteRep', '-2' ],
  [ 'AnswerUpVoteRep', '10' ],
  [ 'AnswerDownVoteRep', '-2' ],
  [ 'AllowSelfVotes', 'false' ],
  [ 'AskingGuidance', '<p>Questions get better answers if they...</p><ul><li>are specific</li><li>are not mostly '\
                      'or entirely based on opinions</li><li>are well written</li></ul>' ],
  [ 'AnsweringGuidance', '<p>When answering, remember to...</p><ul><li><strong>answer the question</strong> - posts '\
                         'that don\'t address the problem clutter up the thread</li><li><strong>explain why you\'re '\
                         'right</strong> - not everyone knows what you do, so explain why this is the answer</li></ul>' ],
  [ 'AdministratorContactEmail', 'contact@example.com' ],
  [ 'HotQuestionsCount', 5 ]
]

default_privileges = [
  [ 'Edit', 500 ],
  [ 'Delete', 1000 ],
  [ 'ViewDeleted', 1000 ]
]

default_settings.each do |name, value|
  SiteSetting.create(name: name, value: value)
end

default_privileges.each do |name, threshold|
  Privilege.create(name: name, threshold: threshold)
end

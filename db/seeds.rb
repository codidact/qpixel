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
  [ 'AllowSelfVotes', 'false' ]
]

default_settings.each do |name, value|
  SiteSetting.create(name: name, value: value)
end

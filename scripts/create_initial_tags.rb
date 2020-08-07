@options = {}
OptionParser.new do |opts|
  opts.on('-c COMMUNITY_ID', '--community=COMMUNITY_ID', Integer)
  opts.on('-t TAG_SET_ID', '--tag-set=TAG_SET_ID', Integer) do |t|
    @options[:tag_set] = t
  end
end.parse!(into: @options)

tags = ARGV

created = Tag.create(tags.map { |t| { name: t, community_id: @options[:community], tag_set_id: @options[:tag_set] } })
puts "Created #{created.size} tags."
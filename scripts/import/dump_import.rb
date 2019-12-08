require_relative 'base_import'

class DumpImport < BaseImport
  def initialize(options)
    @options = options
  end

  def load_file(file)
    base_path = @options.path
    base_tag = file.downcase.gsub('_', '')
    doc = Nokogiri::XML(File.read("#{base_path}/#{file}.xml"))
    rows = doc.at_css(base_tag)
    rows.element_children.map { |ec| ec.attributes.map { |an, attr| [an, attr&.value || an] }.to_h }
  end

  def construct_user(row_data)
    user_data = if row_data
                  { display_name: row_data['DisplayName'], user_id: row_data['Id'], account_id: row_data['AccountId'],
                    link: "#{site_base_url}/u/#{row_data['Id']}" }
                else
                  { user_id: nil }
                end
    user_data.map { |k, v| [k.to_s, v] }.to_h
  end

  def construct_post(row_data)
    base = { body: row_data['Body'], body_markdown: ReverseMarkdown.convert(row_data['Body']), closed_date: row_data['ClosedDate'],
             creation_date: row_data['CreationDate'], last_activity_date: row_data['LastActivityDate'], title: row_data['Title'],
             tags: row_data['Tags']&.scan(/<([^>]+)>/)&.flatten,
             link: "#{site_base_url}/#{row_data['PostTypeId'] == '1' ? 'q' : 'a'}/#{row_data['Id']}" }
    base = base.merge(owner: construct_user(@users.select { |u| u['Id'] == row_data['OwnerUserId'] }[0]))
    base = base.merge(up_vote_count: @votes.select { |v| v['PostId'] == row_data['Id'] && v['VoteTypeId'] == '2' }.size)
    base = base.merge(down_vote_count: @votes.select { |v| v['PostId'] == row_data['Id'] && v['VoteTypeId'] == '3' }.size)
    base = base.merge(answers: @posts.select { |p| p['ParentId'] == row_data['Id'] }.map { |p| construct_post p })
    base.map { |k, v| [k.to_s, v] }.to_h
  end

  def import!
    print "Loading data: posts\r"
    @posts = load_file 'Posts'
    print "Loading data: users\r"
    @users = load_file 'Users'
    print "Loading data: votes\r"
    @votes = load_file 'Votes'
    puts  'Loading data: done  '

    @posts.select { |p| p['PostTypeId'] == '1' }.each do |p|
      constructed = construct_post(p)
      q = create_question(constructed)
      puts "created question #{p['Id']} => #{q.id}"
      if constructed.include?('answers') && constructed['answers'].size > 0
        constructed['answers'].each do |answer|
          a = create_answer q.id, answer
          puts "created answer #{q.id} <=> #{a.id}"
        end
      end
    end
  end
end
class DumpImport
  def self.posts_field_map(community_id, category_id, site_domain)
    {
      id: :id,
      post_type_id: :post_type_id,
      created_at: :creation_date,
      score: :score,
      body: Proc.new { |row| CGI.unescapeHTML(row['body'] || '') },
      body_markdown: Proc.new { |row| CGI.unescapeHTML(row['body'] || '') },
      user_id: :owner_user_id,
      last_activity: :last_activity_date,
      title: Proc.new { |row| CGI.unescapeHTML(row['title'] || '') },
      tags_cache: Proc.new { |row| transform_tags(row) },
      answer_count: :answer_count,
      parent_id: :parent_id,
      att_source: Proc.new { |row| "https://#{site_domain}#{row['post_type_id'].to_s == '1' ? '/q/' : '/a/'}#{row['id']}" },
      att_license_name: Proc.new { |row| determine_license(row)[0] },
      att_license_link: Proc.new { |row| determine_license(row)[1] },
      community_id: community_id,
      category_id: category_id
    }
  end

  def self.users_field_map(site_domain)
    {
      id: :id,
      created_at: :creation_date,
      username: Proc.new { |row| CGI.unescapeHTML(row['display_name'] || '') },
      website: :website_url,
      profile: Proc.new { |row| generate_profile(row, site_domain) },
      profile_markdown: Proc.new { |row| generate_profile(row, site_domain) },
      se_acct_id: :account_id,
      email: Proc.new { |row| "#{row['id']}@stack-import.localhost" }
    }
  end

  def self.transform_tags(row)
    tags = row['tags']&.split('><')&.map { |t| t.gsub(/[<>]/, '') }
    tags.nil? ? nil : "---\n- " + tags.join("\n- ")
  end

  def self.determine_license(row)
    date = DateTime.parse(row['creation_date'])
    if date < Date.new(2018, 5, 2)
      ['CC BY-SA 3.0', 'https://creativecommons.org/licenses/by-sa/3.0/']
    else
      ['CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0/']
    end
  end

  def self.generate_profile(row, site_domain)
    profile_url = "https://#{site_domain}/u/#{row['id']}"
    "<p>This user was automatically created as the author of content sourced from Stack Exchange.</p>" \
    "<p>The original profile on Stack Exchange can be found here: <a href=\"#{profile_url}\">#{profile_url}</a>"
  end

  # Run an XML transformation from data dump format to a format that can be loaded into MySQL.
  # @param site_domain The domain name of the SE site that we're operating on, i.e. stackoverflow.com. No protocol. Required.
  # @param data_type The data dump data type that we're transforming, i.e. Posts or Users. Required.
  # @param community_id The community ID that records will be inserted into. Required if data_type is Posts.
  # @param category_id The category ID that posts should be inserted into. Required if data_type is Posts.
  # @param dump_path The path to the downloaded, uncompressed data dump directory.
  def self.do_xml_transform(site_domain, data_type, options)
    dump_path = options.path
    community_id = options.community
    category_id = options.category

    input_file_path = File.join(dump_path, "#{data_type}.xml")
    output_file_path = Rails.root.join('import-data', "#{data_type}_Formatted.xml")

    field_map = case data_type
                when 'Posts'
                  DumpImport.posts_field_map(community_id, category_id, site_domain)
                when 'Users'
                  DumpImport.users_field_map(site_domain)
                else
                  raise ArgumentError, "Unsupported data type #{data_type.inspect}"
                end

    document = Nokogiri::XML(File.read(input_file_path))
    rows = document.css("#{data_type.downcase} row").to_a
    rows = rows.map { |r| r.attributes.map { |n, a| [n.underscore, a.content] }.to_h }

    # Allow calling code to add and filter rows before we dump to file.
    rows = block_given? ? yield(rows) : rows

    progress = ProgressBar.create(title: "#{data_type} (#{rows.size})", total: rows.size, progress_mark: '█')

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.resultset do
        rows.each do |row|
          xml.row do
            field_map.each do |field, source|
              if source.is_a? Symbol
                xml.send(field, row[source.to_s])
              elsif source.is_a? Proc
                xml.send(field, source.call(row))
              else
                xml.send(field, source)
              end
            end
          end
          progress.increment
        end
      end
    end

    File.write(output_file_path, builder.to_xml(encoding: 'UTF-8'))
    [rows, output_file_path]
  end

  def self.generate_tags(posts, options)
    output_file_path = Rails.root.join('import-data', 'Tags_Formatted.xml')

    unique_tags = posts.map { |p| p['tags'].present? ? p['tags'].split('><').map { |t| t.gsub(/[<>]/, '') } : [] }
                       .flatten.uniq
    progress = ProgressBar.create(title: "Tags (#{unique_tags.size})", total: unique_tags.size, progress_mark: '█')

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.resultset do
        unique_tags.each do |tag|
          xml.row do
            xml.community_id options.community
            xml.tag_set_id options.tag_set
            xml.name tag
            xml.created_at DateTime.now.iso8601
            xml.updated_at DateTime.now.iso8601
          end
          progress.increment
        end
      end
    end

    File.write(output_file_path, builder.to_xml(encoding: 'UTF-8'))
    output_file_path
  end
end

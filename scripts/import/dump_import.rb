class DumpImport
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

  def self.generate_profile(row)
    profile_url = "https://#{SITE}/u/#{row['id']}"
    "<p>This user was automatically created as the author of content sourced from Stack Exchange.</p>" \
    "<p>The original profile on Stack Exchange can be found here: <a href=\"#{profile_url}\">#{profile_url}</a>"
  end

  # Run an XML transformation from data dump format to a format that can be loaded into MySQL.
  # @param site_domain The domain name of the SE site that we're operating on, i.e. stackoverflow.com. No protocol. Required.
  # @param data_type The data dump data type that we're transforming, i.e. Posts or Users. Required.
  # @param community_id The community ID that records will be inserted into. Required if data_type is Posts.
  # @param category_id The category ID that posts should be inserted into. Required if data_type is Posts.
  # @param dump_path The path to the downloaded, uncompressed data dump directory.
  def self.do_xml_transform(site_domain: nil, data_type: nil, community_id: nil, category_id: nil, dump_path: nil)
    if site_domain.nil? || data_type.nil? || dump_path.nil? || data_type == 'Posts' && (community_id.nil? || category_id.nil?)
      raise ArgumentError, 'Invalid arguments'
    end

    input_file_path = File.join(dump_path, "#{data_type}.xml")
    output_file_path = File.join(dump_path, "#{data_type}_Formatted.xml")

    
  end
end

DumpImport.do_xml_transform
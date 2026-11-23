# Expand as necessary

['tag_children'].each do |script_name|
  Rails.cache.persistent "#{script_name}_sql", clear: true do
    script_path = Rails.root.join("db/scripts/#{script_name}.sql")
    File.read(script_path)
  end
end


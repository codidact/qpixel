AppConfig ||= OpenStruct.new

Dir.glob(Rails.root.join('config/config/*.yml')).each do |f|
  basename = Pathname.new(f).relative_path_from(Pathname.new(Rails.root.join('config/config'))).to_s
  root_key = basename.gsub('.yml', '')
  AppConfig[root_key] = YAML.load(File.read(f))
end
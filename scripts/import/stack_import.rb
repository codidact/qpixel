require 'ostruct'
require 'optparse'
require 'open-uri'

@options = OpenStruct.new
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: rails r stack_import.rb [options]"

  opts.on('-s', '--site=SITE', "Stack Exchange site API parameter to operate on") do |site|
    @options.site = site
  end

  opts.on('-k', '--key=KEY', 'Stack Exchange API key') do |key|
    @options.key = key
  end

  opts.on('-u', '--user=USER', 'Import only questions from a specified user ID') do |user|
    @options.user = user
  end

  opts.on('-t', '--tag=TAG', 'Import only questions (with their answers) from a specified tag') do |tag|
    @options.tag = tag
  end

  opts.on('-d', '--source=SOURCE', 'Source data from specified SOURCE, either "api" or "dump"') do |source|
    if ['api', 'dump'].include? source.downcase
      @options.source = source.downcase.to_sym
    else
      puts 'FATAL: Source must be one of "api" or "dump"'
      exit 1
    end
  end

  opts.on('-f', '--dump-file=FILE', 'Specify the path to the decompressed data dump file.') do |path|
    @options.path = path
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end
opt_parser.parse!

unless @options.site.present?
  puts "FATAL: Site must be specified"
  exit 1
end

if (@options.source == :api && !@options.key.present?) || (@options.source == :dump && !@options.path.present?)
  puts "FATAL: Data source details must be specified (key for API, file for dump)"
  exit 1
end

$system_user = User.find(-1)
$user_id_map = {}

if @options.source == :api
  require_relative './api_import'
  APIImport.new(@options).import!
elsif @options.source == :dump
  require_relative './dump_import'
  DumpImport.new(@options).import!
end
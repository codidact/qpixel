require 'ostruct'
require 'optparse'
require 'open-uri'
require 'csv'

require_relative 'api_import'
require_relative 'dump_import'
require_relative 'base_import'

$logger = ::Logger.new(STDOUT)
$logger.level = :info

def msg2str(msg)
  case msg
  when ::String
    msg
  when ::Exception
    "#{msg.message} (#{msg.class})\n" <<
      (msg.backtrace || []).join("\n")
  else
    msg.inspect
  end
end

$logger.formatter = proc do |severity, time, progname, msg|
  colors = { 'DEBUG' => "\033[0;37m", 'INFO' => "\033[1;36m", 'WARN' => "\033[1;33m", 'ERROR' => "\033[1;31m", 'FATAL' => "\033[0;31m" }
  "%s, [%s #%d] %s%5s%s -- %s: %s\n" % [severity[0..0], time.strftime('%Y-%m-%d %H:%M:%S'), $$, colors[severity], severity,
                                         "\033[0m", progname, msg2str(msg)]
end

ERROR_CODES = {
  no_site: 1,
  undefined_mode: 2,
  invalid_specifier: 3,
  invalid_query_format: 4
}

@options = OpenStruct.new
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: rails r stack_import.rb [options]"

  opts.on('-s', '--site=SITE', "Stack Exchange site API parameter to operate on") do |site|
    @options.site = site
  end

  opts.on('-k', '--key=KEY', 'Stack Exchange API key') do |key|
    @options.key = key
  end

  opts.on('-u', '--user=USER', Integer, 'Import only content from a specified user ID') do |user|
    @options.user = user
  end

  opts.on('-t', '--tag=TAG', 'Import only questions (with their answers) from a specified tag') do |tag|
    @options.tag = tag
  end

  opts.on('-q', '--query=REVISION_ID', 'Import posts whose IDs are returned by the SEDE query provided') do |query|
    @options.query = query
  end

  opts.on('-d', '--dump=FILE', 'Specify the path to the decompressed data dump directory') do |path|
    @options.path = path
  end

  opts.on('-i', '--quiet', 'Produce less output') do
    $logger.level = :warn
  end

  opts.on('-v', '--verbose', 'Produce more output') do
    $logger.level = :debug
  end

  opts.on('-c', '--community=ID', Integer, 'Specify the community ID to add imported content to') do |community|
    @options.community = community
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end
opt_parser.parse!

unless @options.site.present?
  $logger.fatal 'Site must be specified'
  exit ERROR_CODES[:no_site]
end

unless @options.key.present?
  $logger.warn 'No key specified. Can run without one, but only for a limited run. Large imports will require a key for added quota.'
end

RequestContext.community = Community.find(@options.community)

$mode = OpenStruct.new
if @options.query.present?
  $mode.mode = :query
  $mode.specifier = @options.query
elsif @options.user.present?
  $mode.mode = :user
  $mode.specifier = @options.user
elsif @options.tag.present?
  $mode.mode = :tag
  $mode.specifier = @options.tag
else
  $mode.mode = :all
  $mode.specifier = nil
end

$logger.info "Selected mode #{$mode.mode.to_s}"
$logger.info $mode.specifier.present? ? "Mode specifier #{$mode.specifier.inspect}" : 'No mode specifier'

# ====================================================================================== #

api_importer = APIImport.new(@options)
dump_importer = DumpImport.new(@options)
base_importer = BaseImport.new(@options, dump_importer, api_importer)

case $mode.mode
when :query
  unless $mode.specifier =~ /^\d+$/
    $logger.fatal "Mode specifier #{$mode.specifier.inspect} invalid for selected mode. Expected /^\\d+$/."
    exit ERROR_CODES[:invalid_specifier]
  end

  query_csv_uri = "https://data.stackexchange.com/#{@options.site}/csv/#{$mode.specifier}"
  resp = Net::HTTP.get_response(URI(query_csv_uri))
  rows = CSV.parse(resp.body)[1..-1]
  $logger.info "#{rows.size} rows returned"

  unless rows.all? { |r| r.size == 1 && r[0] =~ /^\d+$/ }
    $logger.fatal "Query revision #{$mode.specifier} returned invalid data format. Expected only Id field in each row."
    exit ERROR_CODES[:invalid_query_format]
  end

  base_importer.import rows.flatten
when :user

when :tag

when :all

else
  $logger.fatal "Selected mode '#{$mode.mode.to_s}' is not defined"
  exit ERROR_CODES[:undefined_mode]
end
require 'ostruct'
require 'optparse'
require 'open-uri'

require_relative 'api_import'
require_relative 'dump_import'

$system_user = User.find(-1)
$logger = ::Logger.new(STDOUT)

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
  no_site: 1
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

  opts.on('-q', '--query=QUERY_LINK', 'Import posts whose IDs are returned by the SEDE query provided') do |query|
    @options.query = query
  end

  opts.on('-d', '--dump=FILE', 'Specify the path to the decompressed data dump directory') do |path|
    @options.path = path
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

puts "hi"
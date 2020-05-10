require 'ostruct'
require 'optparse'
require 'open-uri'
require 'csv'

require_relative 'dump_import'

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
  colors = { 'DEBUG' => "\033[0;37m", 'INFO' => "\033[1;36m", 'WARN' => "\033[1;33m", 'ERROR' => "\033[1;31m",
             'FATAL' => "\033[0;31m" }
  "%s, [%s #%d] %s%5s%s -- %s: %s\n" % [severity[0..0], time.strftime('%Y-%m-%d %H:%M:%S'), $$, colors[severity],
                                        severity, "\033[0m", progname, msg2str(msg)]
end

def domain_from_api_param(api_param)
  nonstandard = {
    stackoverflow: '.com',
    superuser: '.com',
    serverfault: '.net',
    askubuntu: '.com',
    mathoverflow: '.net'
  }
  if nonstandard.keys.include? api_param.to_sym
    "#{api_param}#{nonstandard[api_param.to_sym]}"
  else
    "#{api_param}.stackexchange.com"
  end
end

ERROR_CODES = {
  no_site: 1,
  undefined_mode: 2,
  invalid_specifier: 3,
  invalid_query_format: 4,
  no_query: 5
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

  opts.on('-t', '--category=ID', Integer, 'Specify the category ID which imported posts should be added') do |category|
    @options.category = category
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

unless @options.query.present?
  $logger.fatal 'Query revision ID must be specified'
  exit ERROR_CODES[:no_query]
end

unless @options.key.present?
  $logger.warn 'No key specified. Can run without one, but only for a limited run. Large imports will require a key ' \
               'for added quota.'
end

RequestContext.community = Community.find(@options.community)

# ==================================================================================================================== #

domain = domain_from_api_param(@options.site)

users = DumpImport.do_xml_transform(site_domain: domain, data_type: 'Users', dump_path: @options.path)
posts = DumpImport.do_xml_transform(site_domain: domain, data_type: 'Posts', community_id: @options.community,
                                    category_id: @options.category, dump_path: @options.path)

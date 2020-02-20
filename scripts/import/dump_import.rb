require 'ostruct'
require 'thwait'

require_relative 'base_import'

class DumpImport < BaseImport
  def initialize(options)
    @options = options
    @xml_data = {}

    $logger.debug 'Loading XML dump data'

    directory_path = File.expand_path @options.path
    files = Dir.glob("*.xml", base: directory_path)
    threads = files.map { |f| "#{directory_path}/#{f}" }.map.with_index do |file, idx|
      Thread.new do
        basename = File.basename(file).gsub('.xml', '')

        $logger.debug "Loading: #{basename} (#{idx + 1}/#{files.size})"

        data_type = basename.underscore.to_sym
        document = Nokogiri::XML(File.read(file))
        rows = document.css("#{basename.downcase} row").map do |r|
          struct = OpenStruct.new
          r.attributes.each { |n, a| struct[n.underscore.to_sym] = a.content }
          struct
        end
        @xml_data[data_type] = rows

        $logger.debug "         #{basename}: #{rows.size}"
      end
    end
    ThreadsWait.all_waits(*threads)

    $logger.debug 'Load done'
  end

  def method_missing(method, *args, &block)
    if @xml_data.include? method.to_sym
      @xml_data[method.to_sym]
    else
      raise
    end
  end
end
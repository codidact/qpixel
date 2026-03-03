options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: rails r scripts/recalc_abilities.rb [options]"

  opts.on('-v', '--verbose', 'Run with additional logging') do
    options[:verbose] = true
  end

  opts.on('-q', '--quiet', 'Run with minimal logging') do
    options[:quiet] = true
  end
end.parse!

RecalcAbilitiesJob.perform_now(options)

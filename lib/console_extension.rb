module ConsoleExtension
  extend ActiveSupport::Concern

  included do
    console do
      Rails.logger.silence do
        console_init_community
      end
    end
  end

  def console_init_community
    community_count = Community.count
    if community_count.zero?
      puts "\e[31m(!) You have not yet created any communities.\e[0m"
      puts 'Create a community by entering:'
      puts ''
      puts "  Community.create(name: 'my community name', host: 'my.site.com')"
      puts '  Rails.cache.clear'
      puts ''

      if Rails.env.development?
        begin
          port = Rails::Server::Options.new.parse!(ARGV)[:Port] || 3000
        rescue
          port = 3000
        end
        puts "Since you are running in development mode, you probably want to set host to localhost:#{port}"
        puts ''
      elsif Rails.env.production?
        puts 'Since you are running in production mode, set host to your fully qualified domain name without http(s).'
        puts 'For example, if you host your site at https://meta.codidact.org, set host to meta.codidact.org'
        puts ''
      end
      puts 'For more information, see the set up instructions.'
    elsif community_count == 1
      community = Community.first
      RequestContext.community = community
      puts "\e[32m(!) Found one community, set current community to #{community.name} @ #{community.host}\e[0m"
    else
      community = Community.find_by(host: 'localhost:3000') if Rails.env.development?
      community ||= Community.first
      RequestContext.community = community
      puts "\e[32m(!) Found multiple communities, set current community to #{community.name} @ #{community.host}\e[0m"
      puts ''
      puts 'You can change your current community by entering:'
      puts ''
      puts '  RequestContext.community = Community.find_by(...)'
      puts ''
      puts "You can use `host: 'my.host'` or `name: 'community name'` in place of the dots"
    end
    puts ''
  rescue
    puts "\e[31m(!)Unable to load communities. Is your database configuration correct?\e[0m"
  end
end

# Create module that can be included as  in the .irbrc
module Qpixel
  def self.irb!
    IRB::Irb.class_eval do
      private

      def self.rails_environment
        case Rails.env
        when 'development'
          "\e[32mdev\e[0m"
        when 'production'
          "\e[31mprod\e[0m"
        when 'staging'
          "\e[32mstag\e[0m"
        else
          "\e[31m#{Rails.env}\e[0m"
        end
      end

      def self.qpixel_prompt
        c = RequestContext.community
        "[#{rails_environment}] [\e[34m#{c&.name || '-'} @ #{c&.host || '-'}\e[0m]"
      end
    end

    IRB::Irb.class_eval do
      # Define an alternative string dup method which will redetermine the prompt part if community changes
      qpixel_block = proc do |s|
        def s.dup
          IRB::Irb.qpixel_prompt + self
        end
      end

      IRB.conf[:PROMPT][:QPIXEL] = {
        PROMPT_I: ':%03n> '.tap(&qpixel_block),
        PROMPT_N: ':%03n> '.tap(&qpixel_block),
        PROMPT_S: ':%03n%l '.tap(&qpixel_block),
        PROMPT_C: ':%03n* '.tap(&qpixel_block),
        RETURN: IRB.conf[:PROMPT][:DEFAULT][:RETURN]
      }

      IRB.conf[:PROMPT_MODE] = :QPIXEL
    end
  end
end
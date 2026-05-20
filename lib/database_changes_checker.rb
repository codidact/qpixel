require 'active_record'
require 'octokit'

module QPixel
  class DatabaseChangesChecker
    def initialize(prev_head, current_head, gh_token, pr_number)
      @prev_head = prev_head
      @current_head = current_head
      @pr_number = pr_number
      @client = Octokit::Client.new(access_token: gh_token)
    end

    def changed_migrations
      `git diff --name-only #{@prev_head}..#{@current_head} -- db/migrate`.split("\n")
    end

    def self.relevant_methods
      all_methods = ActiveRecord::Migration::CommandRecorder::ReversibleAndIrreversibleMethods
      all_methods.select do |m|
        m.to_s.end_with?('_table', '_column', '_reference', '_columns', '_column_comment', '_table_comment',
                         '_column_null', '_column_default')
      end
    end

    RelevantMethods = relevant_methods.freeze

    def relevant_lines(migration_file)
      lines = File.readlines(migration_file)
      lines.select do |line|
        line.match?(Regexp.new("^\\s*[a-z_]*(?:#{RelevantMethods.join('|')})"))
      end.map(&:strip)
    end

    def existing_comment
      @client.issue_comments('codidact/qpixel', @pr_number).select do |comment|
        comment.body.start_with?('### Data dump-affecting changes')
      end
    end

    def update_comment(body)
      existing = existing_comment
      if existing.empty?
        @client.add_comment('codidact/qpixel', @pr_number, body)
      else
        @client.update_comment('codidact/qpixel', existing[0].id, body)
      end
    end
  end
end

##
# When executed as a ruby script, arguments:
# [0]: Previous head position from the base branch, for git comparison
# [1]: Current head position from the source branch, for git comparison
# [2]: A GitHub access token to be used to add a comment to the pull request
# [3]: The pull request number to be commented on
##
if __FILE__ == $PROGRAM_NAME
  prev_head, current_head, gh_token, pr_number = ARGV

  if [prev_head, current_head, gh_token, pr_number].any?(&:nil?)
    puts "Missing arguments. Usage: ruby #{__FILE__} <prev_head> <current_head> <gh_token> <pr_number>"
    exit 1
  end

  checker = QPixel::DatabaseChangesChecker.new(prev_head, current_head, gh_token, pr_number)

  migrations = checker.changed_migrations
  lines = migrations.to_h { |m| [m, checker.relevant_lines(m)] }

  unless lines.empty?
    title = '### Data dump-affecting changes'
    blurb = 'This pull request changes DB schema and may affect what data is included in the data dump. Please review:'
    lines_text = lines.map { |m, l| "**#{m}**\n```\n#{l.join("\n")}\n```" }.join("\n\n")
    checker.update_comment("#{title}\n\n#{blurb}\n\n#{lines_text}")
  end
end

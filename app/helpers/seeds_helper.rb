module SeedsHelper
  # Gets the list of seed file paths
  # @param seed_name [String, nil] optional specific seed name to run
  # @return [Array<String>]
  def self.files(seed_name)
    find_glob = if seed_name.present?
                  "db/seeds/**/#{seed_name.underscore}.yml"
                else
                  'db/seeds/**/*.yml'
                end

    # Get all seed files and determine their model types
    Dir.glob(Rails.root.join(find_glob))
  end

  # Parses model classes from the list of file paths
  # @param files [Array<String>] list of seed file paths
  # @return [Array<Class>]
  def self.types(files)
    files.map do |f|
      basename = Pathname.new(f).relative_path_from(Pathname.new(Rails.root.join('db/seeds'))).to_s
      basename.gsub('.yml', '').singularize.classify.constantize
    end
  end

  # Prioritizes models such that dependent ones are created after the specified ones
  # @param types [Array<Class>] list of model classes
  # @param files [Array<String>] list of seed file paths
  # @return [Hash<String, Class>]
  def self.prioritize(types, files)
    priority = [PostType, CloseReason, License, TagSet, PostHistoryType, User, Ability, CommunityUser, Filter]

    files.zip(types).to_h.sort do |a, b|
      (priority.index(a.second) || 999) <=> (priority.index(b.second) || 999)
    end.to_h
  end

  Stats = Struct.new('Stats', :created, :updated, :errored, :skipped) do |struct|
    struct.members.each do |member|
      define_method "add_#{member}" do |num|
        self[member] += num
      end
    end

    def <<(other)
      members.each do |member|
        send("add_#{member}", other[member])
      end
    end

    def print
      members.map { |m| self[m]&.positive? ? "#{m} #{self[m]}" : nil }
             .compact
             .join(', ')
    end
  end
end

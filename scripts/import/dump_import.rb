require 'ostruct'
require 'thwait'

class DumpImport
  def initialize(options)
    @options = options
    @xml_data = {}

    @system_user = User.find(-1)

    $logger.info 'Loading XML dump data'

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

    $logger.info 'Load done'
  end

  def method_missing(method, *args, &block)
    if @xml_data.include? method.to_sym
      @xml_data[method.to_sym]
    else
      raise NotImplementedError
    end
  end

  def site_base_url
    site_param = @options.site
    non_se = {stackoverflow: 'com', superuser: 'com', serverfault: 'com', askubuntu: 'com', mathoverflow: 'net', stackapps: 'com'}
    included = non_se.keys.map(&:to_s).select { |k| site_param.include? k }
    if included.size > 0
      "https://#{included[0]}.#{non_se[included[0]]}"
    else
      "https://#{site_param}.stackexchange.com"
    end
  end

  def post_data(post)
    # { answers: post_data[]?, body: string, body_markdown: string, closed_date: integer?, creation_date: integer,
    #   down_vote_count: integer, last_activity_date: integer, owner: shallow_user, title: string?, tags: string[]?,
    #   up_vote_count: integer, link: string }
    post_data = { body: post.body, body_markdown: QuestionsController.renderer.render(post.body),
                  creation_date: post.creation_date, last_activity_date: post.last_activity_date,
                  owner: {'user_id' => post.owner_user_id}, link: "#{site_base_url}/q/#{post.id}" }
    if post.post_type_id == '1'
      post_data = post_data.merge(title: post.title, tags: post.tags&.split(/[<>]/)&.reject(&:empty?))
      closed_at = post_closed_at(post)
      unless closed_at.nil?
        post_data[:closed_at] = closed_at
      end
    end

    post_data[:up_vote_count] = votes.select { |v| v.post_id == post.id && v.vote_type_id == '2' }.size
    post_data[:down_vote_count] = votes.select { |v| v.post_id == post.id && v.vote_type_id == '3' }.size

    post_data
  end

  def post_closed_at(post)
    # 10: Closed
    # 11: Reopened
    events = post_history.select { |ph| ['10', '11'].include?(ph.post_history_type_id) && ph.post_id == post.id }
    sorted = events.sort_by(&:creation_date)
    sorted.last&.post_history_type_id == '10' ? sorted.last.creation_date : nil
  end

  def tag_posts(tag)
    posts.select { |p| p.tags.include? "<#{tag}>" }
  end

  def user_posts(user_id)
    posts.select { |p| p.user_id.to_s == user_id.to_s }
  end
end
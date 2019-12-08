require_relative 'base_import'

class APIImport < BaseImport
  def initialize(options)
    @options = options
  end

  def get_data(uri, params)
    page = 1
    params['pagesize'] = 100
    params['key'] = @options.key
    params['site'] = @options.site
    has_more = true
    returns = []
    items = []

    while has_more
      full_uri = uri + '?' + params.map { |k, v| "#{k.to_s}=#{v.to_s}" }.join('&')
      data = JSON.parse(open(full_uri).read)
      received_at = DateTime.now

      if block_given?
        returns << yield(data['items'])
      else
        items.concat data['items']
      end

      if data['backoff'].present?
        sleep_until = received_at + data['backoff'].seconds
        sleep_seconds = sleep_until - DateTime.now
        puts "backing off #{sleep_seconds}s"
        sleep sleep_seconds
      end
      has_more = data['has_more']
      page += 1
    end

    if block_given?
      returns
    else
      items
    end
  end

  def import!
    data_uri, params = if @options.user.present?
                         ["https://api.stackexchange.com/2.2/users/#{@options.user}/questions",
                          {filter: '!FRQ4VTQp2su7)pS5ZMF4xs7LvHDOch0tf*Xw0bzhr2C8QSBKhCzTFTOSUrhHg)OkIuzNxhOD', sort: 'votes'}]
                       elsif @options.tag.present?
                         ["https://api.stackexchange.com/2.2/questions",
                          {tagged: @options.tag, filter: '!FRQ4VTQp2su7)pS5ZMF4xs7LvHDOch0tf*Xw0bzhr2C8QSBKhCzTFTOSUrhHg)OkIuzNxhOD',
                           sort: 'votes'}]
                       else
                         ["https://api.stackexchange.com/2.2/questions",
                          {filter: '!FRQ4VTQp2su7)pS5ZMF4xs7LvHDOch0tf*Xw0bzhr2C8QSBKhCzTFTOSUrhHg)OkIuzNxhOD', sort: 'votes'}]
                       end

    get_data data_uri, params do |items|
      items.each do |item|
        q = create_question item
        puts "created question #{item['id']} => #{q.id}"
        if item['answers'].present?
          item['answers'].each do |answer|
            a = create_answer q.id, answer
            puts "created answer #{answer['id']} => #{a.id}"
          end
        end
      end
    end
  end
end
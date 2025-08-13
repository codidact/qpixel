class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.fuzzy_search(term, **cols)
    sanitized = sanitize_for_search term, **cols
    select(Arel.sql("`#{table_name}`.*, #{sanitized} AS search_score"))
  end

  def self.match_search(term, **cols)
    sanitized = sanitize_for_search term, **cols
    select(Arel.sql("`#{table_name}`.*, #{sanitized} AS search_score")).where(sanitized)
  end

  def self.sanitize_name(name)
    name.to_s.delete('`').insert(0, '`').insert(-1, '`')
  end

  def match_search(term, **cols)
    ApplicationRecord.match_search(term, **cols)
  end

  def attributes_print(join: ', ')
    attributes.map do |k, v|
      val = v.inspect.length > 100 ? "#{v.inspect[0, 100]}..." : v.inspect
      "#{k}: #{val}"
    end.join(join)
  end

  def self.sanitize_for_search(term, **cols)
    cols = cols.map do |k, v|
      if v.is_a?(Array)
        v.map { |vv| "#{sanitize_name k}.#{sanitize_name vv}" }.join(', ')
      else
        "#{sanitize_name k}.#{sanitize_name v}"
      end
    end.join(', ')

    ActiveRecord::Base.send(:sanitize_sql_array, ["MATCH (#{cols}) AGAINST (? IN BOOLEAN MODE)", term])
  end

  def self.sanitize_sql_in(ary)
    return '(NULL)' unless ary.present? && ary.respond_to?(:map)

    res = ActiveRecord::Base.sanitize_sql_array([ary.map { |_e| '?' }.join(', '), *ary])
    "(#{res})"
  end

  # This is a BRILLIANT idea. BRILLIANT, I tell you.
  def self.with_lax_group_rules
    return unless block_given?

    transaction do
      connection.execute 'SET @old_sql_mode = @@sql_mode'
      connection.execute "SET SESSION sql_mode = REPLACE(REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY,', ''), " \
                         "'ONLY_FULL_GROUP_BY', '')"
      yield
      connection.execute 'SET SESSION sql_mode = @old_sql_mode'
    end
  end

  def self.useful_err_msg
    [
      'The inverted database guide has found an insurmountable problem. Please poke it with a ' \
        'paperclip before anyone finds out.',
      'The integral output port has found a problem. Please take it back to the shop and take ' \
        'the rest of the day off.',
      'Congratulations. You have reached the end of the internet.',
      'The Spanish Inquisition raised an unexpected error. Cannot continue without comfy-chair-interrogation.',
      'The server halted in an after-you loop.',
      'A five-level precedence operation shifted too long and cannot be recovered without data loss. ' \
        'Please re-enable the encryption protocol.',
      'The server\'s headache has not improved in the last 24 hours. It needs to be rebooted.',
      'The primary LIFO data recipient is currently on a holiday and will not be back before next Thursday.',
      'The operator is currently trying to solve their Rubik\'s cube. We will come back to you when the ' \
        'second layer is completed.',
      'The encryption protocol offered by the client predates the invention of irregular logarithmic ' \
        'functions.',
      'The data in the secondary (backup) user registry is corrupted and needs to be re-filled with ' \
        'random data again.',
      'This community has reached a critical mass and collapsed into a black hole. Currently trying to ' \
        'recover using Hawking radiation.',
      'Operations are on pause while we attempt to recapture the codidactyl. Please hold.',
      'The data center is on fire. Please hold while we activate fire suppression systems.',
      'The reciprocal controller flag is set incorrectly. Please stand on your head and rickroll yourself to fix this.',
      'The quantum cache has become uncertain. Please observe it again after making a cup of tea.',
      'The recursive handshake timed out while waiting for itself to finish. Try waving at yourself in a mirror ' \
        'until it responds.',
      'The left-handed API key doesn\'t fit this right-handed endpoint. Please rotate it 180 degrees while humming the API theme song.',
      'Your session was garbage-collected for leaving crumbs in the cookie jar. Kindly sweep the cookies into a ' \
        'jar-shaped folder.',
      'Your request fell through a race condition and finished second. Present it with a silver medal and try again.',
      'The DNS insists today it stands for \'Did Not Start\'. Please send it motivational cat posters.',
      'The OAuth token is shy. Whisper your scopes softly and offer it a comfort blanket.',
      'The distributed consensus reached a polite disagreement. Break the tie with a round of rock-paper-scissors.',
      'The feature flag tripped over a rug and toggled itself off. Please help it up and brush off the dust.',
      'The uptime counter overflowed into nap time. Wake it gently with a teaspoon of coffee.',
      'The cron job saw its shadow and scheduled six more weeks of maintenance. Offer it a flashlight and try again.',
      'The heisenbug vanished when we opened the logs. Please look away and try again.',
      'The Kubernetes pod drifted out to sea. Dispatch a small boat with sandwiches.',
      'The retry policy is composing a strongly worded letter to the server. Offer a thesaurus for better results.',
      'The message queue joined a queue. Estimated wait time: variable. Send it a good book.',
      'The microservice macroed itself and forgot how to be small. Remind it of its humble beginnings.',
      'The database index is on a gap year. Send postcards to encourage its return.',
      'The deploy canary learned to sing and flew away. Try luring it back with birdseed.',
      'Single sign-on stepped out to find itself. Back soon. Leave a trail of breadcrumbs.',
      'The entropy pool is empty. Kindly imagine wiggling your mouse.',
      'The RAID array eloped with a NAS. Send congratulations and request a postcard.',
      'The config file contains more opinions than agreement. Appoint a moderator.',
      'The null pointer was so moved it pointed somewhere. Politely direct it back.',
      'The stack is overflowing with feelings. Fetching tissues. Offer emotional support.',
      'The exception handler forgot its mitts. Knit it a pair.',
      'The SSL certificate expired in dog years. Bake it a birthday cake.',
      'The WebSocket is sulking in silent mode. Send a heartfelt apology.',
      'The API gateway misplaced the keys to the database. Check under the welcome mat.',
      'The firmware updated its relationship status to \'complicated\'. Send couples counselling pamphlets.',
      'The load balancer is weighing its options. Provide a set of calibrated scales.',
      'The build pipeline tripped over a merge conflict and needs a plaster. Apply gentle pressure.',
      'The logger switched to interpretive dance. Learn the choreography to decode the message.',
      'The search index refuses to be found. Host a welcome‑back party.',
      'The container misplaced its container. Check the lost‑and‑found container.',
      'The recursive acronym needs a breather before it expands again. Offer a paper bag.',
      'The data lake froze over. Please try ice skating.',
      'The fiber was delayed by a lorry attempting a three-point turn. Offer to navigate.',
      'The server popped out for a bacon butty. Back shortly. Fry an extra one for its return.',
      'The permissions matrix rotated 90 degrees and became modern art. Hang it in a gallery.',
      'Your cookie consent banner ate the cookies. Supply a healthy snack alternative.',
      'The scheduler double-booked Tuesday with next Tuesday. Buy it a new calendar.',
      'The GPU is busy appreciating gradients in a sunset. Offer it a camera.',
      'The CLI took everything literally and nothing personally. Send it idioms to process.',
      'The time server is early, the database is late, and reality is pending. Send them a group chat invite.',
      'Your session collided with a parallel universe and yielded a merge conflict. Try diplomatic talks.',
      'The health check caught a cold. Sending soup packets. Add a warm blanket.',
      'The sandbox discovered a cat and refuses to collapse the wavefunction. Provide a cardboard box.',
      'The debugger hit a breakpoint and started journaling. Offer coloured pens.',
      'The profiler is timing itself. Results may vary. Suggest it use a stopwatch.',
      'The error reporter experienced an error and needs a quiet moment. Light a scented candle.',
      'The audit log is practicing mindfulness and noticed your request drift by. Join it for meditation.',
      'The dependency tree is climbing itself. Mind the branches. Offer a ladder.',
      'The semaphore got stage fright and won’t signal. Provide an encouraging audience.',
      'The background job went foreground and now refuses to blend in. Offer camouflage.',
      'The clipboard copied the vibe but not the content. Try a mood reset.',
      'The keyboard buffer is full of unsent compliments. Press send on kindness.',
      'The ops runbook recommends tea, biscuits, and a gentle retry. Add a scone.',
      'The metrics exporter is measuring twice and cutting never. Provide scissors.',
      'The NTP sync is waiting for time to catch up with itself. Send it a postcard from the future.',
      'The transaction forgot its commit vows and wandered off. Hold a recommitment ceremony.',
      'The scheduler moved your slot to the next available epoch. Estimated delay: 73 years.',
      'The test suite passed locally and moved abroad. Mail it a travel adaptor.',
      'The feature toggle is indecisive and would like a coin flip. Supply a two‑headed coin.',
      'The namespace is arguing about space. Offer a tape measure.',
      'The host machine asked politely for a host gift. Bring flowers.',
      'The compliance engine needs a hug from a certified hugger. Book a professional cuddle.',
      'The API versioning strategy is writing its memoir. Offer an editor.'
    ]
  end
end

module UserSortable
  # Sort a collection according to a user selection, by mapping user selectable values to column names.
  # SQL injection safe.
  # @param term_opts Hash of search term options
  # @param field_mappings Hash of user-selectable values to column names: +{ age: :created_at, rep: :threshold }+
  # @option term_opts :term [String] A user-provided search term to apply - usually from +params+, e.g. +params[:sort]+.
  #   Should be one of the keys in +field_mappings+.
  # @option term_opts :default [Symbol] A column name to apply as the default sort ordering.
  # @return [ActiveRecord::Relation] A relation of the current type, with the sort ordering applied.
  def user_sort(term_opts, **field_mappings)
    default = term_opts[:default] || :created_at
    requested = term_opts[:term]
    direction = term_opts[:direction] || :desc
    if requested.nil? || field_mappings.exclude?(requested.to_sym)
      $active_search_param = default
      default.is_a?(Symbol) ? order(default => direction) : order(default)
    else
      requested_val = field_mappings[requested.to_sym]
      $active_search_param = requested_val
      requested_val.is_a?(Symbol) ? order(requested_val => direction) : order(requested_val)
    end
  end
end

klasses = [ActiveRecord::Relation]
klasses << if defined? ActiveRecord::Associations::CollectionProxy
             ActiveRecord::Associations::CollectionProxy
           else
             ActiveRecord::Associations::AssociationCollection
           end

ActiveRecord::Base.extend UserSortable
klasses.each { |klass| klass.send(:include, UserSortable) }

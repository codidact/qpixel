class DatabaseImport
  def initialize(options, domain)
    @options = options
    @domain = domain

    query_opts = ActiveRecord::Base.connection.raw_connection.query_options
    db_config = query_opts.slice(:adapter, :encoding, :host, :port, :username, :password)
    @database = query_opts[:database]
    @base = ActiveRecord::Base

    ActiveRecord::Base.establish_connection(db_config.merge(local_infile: true))
    @conn = ActiveRecord::Base.connection

    query 'CREATE DATABASE IF NOT EXISTS qpixel_imports'
    query 'USE qpixel_imports'

    create_empty_tables
  end

  def table(name, database = 'qpixel_imports')
    "#{@conn.quote_column_name(database)}.#{@conn.quote_column_name(name)}"
  end

  def column(name, table: nil)
    if table.present?
      "#{@conn.quote_column_name(table)}.#{@conn.quote_column_name(name)}"
    else
      @conn.quote_column_name(name)
    end
  end

  def column_list(ary, table: nil)
    "(#{ary.map { |n| column(n, table: table) }.join(', ')})"
  end

  def query(sql, log: true)
    if log
      $logger.debug "\033[1;35m#{sql}\033[0m"
    end
    @conn.execute(sql).to_a
  end

  def create_empty_tables
    ['posts', 'users', 'tags'].each do |t|
      query "CREATE TABLE IF NOT EXISTS #{table(t)} LIKE #{table(t, @database)}"
      query "DELETE FROM #{table(t)}"
    end
  end

  def load_data(file_path, table_name, field_list)
    sql = @base.sanitize_sql_array ["LOAD XML LOCAL INFILE ? INTO TABLE #{table(table_name)} #{column_list(field_list)}",
                                    file_path]
    query sql
  end

  def run
    # We only want questions and answers; nuke anything that isn't
    query "DELETE FROM #{table 'posts'} WHERE #{column 'post_type_id'} NOT IN (1, 2)"

    # Change post user IDs to SE account IDs so we can re-associate them with users later
    query "UPDATE #{table 'posts'} p LEFT JOIN #{table 'users'} u ON p.user_id = u.id " \
          "SET p.user_id = -1 WHERE u.id IS NULL;"
    query "UPDATE #{table 'posts'} p LEFT JOIN #{table 'users'} u ON p.user_id = u.id " \
          "SET p.user_id = u.se_acct_id WHERE p.user_id != -1;"

    # Add user records to the live database, but only those we don't already have
    user_fields = column_list ['created_at', 'username', 'website', 'profile', 'profile_markdown', 'se_acct_id',
                               'updated_at']
    query "INSERT INTO #{table 'users', @database} #{user_fields} " \
          "SELECT created_at, username, website, profile, profile_markdown, se_acct_id, CURRENT_TIMESTAMP " \
          "FROM #{table 'users'} WHERE se_acct_id IN (" \
          "SELECT u.se_acct_id FROM #{table 'users'} u LEFT JOIN #{table 'users', @database} qu " \
          "ON u.se_acct_id = qu.se_acct_id WHERE qu.id IS NULL)"

    # Add community user records to match
    cu_fields = column_list ['user_id', 'community_id', 'reputation', 'created_at', 'updated_at']
    sql = "INSERT INTO #{table 'community_users', @database} #{cu_fields} " \
          "SELECT id, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM #{table 'users', @database} " \
          "WHERE se_acct_id IN (SELECT DISTINCT se_acct_id FROM #{table 'users'});"
    query @base.sanitize_sql_array([sql, @options.community])

    # Change post user IDs back to the real user IDs from the live database before we insert the posts
    query "UPDATE #{table 'posts'} p LEFT JOIN #{table 'users', @database} u ON p.user_id = u.se_acct_id " \
          "SET p.user_id = u.id WHERE p.user_id != -1;"

    # Add the posts to the live database
    post_fields = column_list ['post_type_id', 'created_at', 'score', 'body', 'body_markdown', 'user_id',
                               'last_activity', 'title', 'tags_cache', 'answer_count', 'parent_id', 'att_source',
                               'att_license_name', 'att_license_link', 'category_id', 'community_id', 'updated_at']
    query "INSERT INTO #{table 'posts', @database} #{post_fields} " \
          "SELECT post_type_id, created_at, score, body, body_markdown, user_id, last_activity, title, tags_cache, " \
          "answer_count, parent_id, att_source, att_license_name, att_license_link, category_id, community_id, " \
          "CURRENT_TIMESTAMP FROM #{table 'posts'}"

    # Post IDs just changed, so we also have to re-associate answers with the correct questions.
    sql = "UPDATE #{table 'posts', @database} pa INNER JOIN #{table 'posts', @database} pq " \
          "ON pq.att_source = CONCAT('https://', ?, '/q/', pa.parent_id) " \
          "SET pa.parent_id = pq.id WHERE pa.post_type_id = 2 AND pa.community_id = ? AND pa.category_id = ?"
    query @base.sanitize_sql_array([sql, @domain, @options.community, @options.category])

    # Add tags to live database
    tags_fields = column_list ['name', 'created_at', 'updated_at', 'community_id', 'tag_set_id']
    query "INSERT INTO #{table 'tags', @database} #{tags_fields} " \
          "SELECT name, current_timestamp, current_timestamp, community_id, tag_set_id FROM #{table 'tags'}"

    # Last step: re-associate tags with posts
    unless @options.skip_tags
      associate_tags
    end

    cleanup
  end

  def associate_tags
    sql = "SELECT name, id FROM #{table 'tags', @database} WHERE tag_set_id = ?"
    tags = query(@base.sanitize_sql_array([sql, @options.tag_set])).to_h
    tags.each do |tag, id|
      ins_sql = "INSERT INTO #{table 'posts_tags', @database} #{column_list ['post_id', 'tag_id']} " \
                "SELECT id, ? FROM #{table 'posts', @database} WHERE tags_cache LIKE ? " \
                "AND community_id = ? AND category_id = ?"
      query @base.sanitize_sql_array([ins_sql, id, "%#{tag}%", @options.community, @options.category])
    end
    $logger.debug "Updated post associations for #{tags.size} tags"
  end

  def cleanup
    # Remove attribution notices from posts where the user isn't an imported user
    sql = "UPDATE #{table 'posts', @database} p INNER JOIN #{table 'users', @database} u ON p.user_id = u.id " \
          "SET p.att_source = NULL, p.att_license_link = NULL, p.att_license_name = NULL " \
          "WHERE u.email NOT LIKE '%localhost' AND p.community_id = ? AND p.category_id = ?"
    query @base.sanitize_sql_array([sql, @options.community, @options.category])

    # Remove duplicate CommunityUser records
    sql = "DELETE a FROM community_users a INNER JOIN community_users b ON a.user_id = b.community_id AND " \
          "a.community_id = b.community_id AND a.id != b.id WHERE a.created_at > b.created_at AND " \
          "a.community_id = ?"
    query @base.sanitize_sql_array([sql, @options.community])

    if @options.zero_scores
      sql = "UPDATE posts SET score = 0 WHERE community_id = ? AND category_id = ?"
      query @base.sanitize_sql_array([sql, @options.community, @options.category])
    end
  end
end
unless Rails.env.development?
  puts "You're on production. Don't be dumb."
  exit 255
end

def exec_sql(sql)
  ActiveRecord::Base.connection.execute sql
end

conn = ActiveRecord::Base.connection
leave_tables = ['ar_internal_metadata', 'schema_migrations']
(conn.tables - leave_tables).each do |t|
  exec_sql "DELETE FROM `#{t}`"
  exec_sql "ALTER TABLE `#{t}` AUTO_INCREMENT=1"
end

Rails.cache.clear

`bundle exec rails db:seed`

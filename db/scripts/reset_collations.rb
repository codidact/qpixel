# frozen_string_literal: true

# Rails is stupid and likes making tables' default charset latin1. When you tell it to use utf8mb4 like it should, it
# decides that all the text columns are going to be latin1_swedish_ci instead, obviously. So, this script is here to
# reset all the table and column collations so that you can run it and then db:schema:dump to get a corrected schema.
#
# Lifesaving reference: https://stackoverflow.com/q/1294117/3160466

tables_columns = ActiveRecord::Base.connection.tables.map { |t| [t, ActiveRecord::Base.connection.columns(t)] }.to_h

tables_columns.each do |t, cs|
  puts t
  puts '  CONVERT TO CHARACTER SET utf8mb4...'
  ActiveRecord::Base.connection.execute "ALTER TABLE `#{t}` CONVERT TO CHARACTER SET utf8mb4;"

  puts '  ALTER DEFAULT CHARSET/COLLATE...'
  ActiveRecord::Base.connection.execute "ALTER TABLE `#{t}` DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"

  puts '  ALTER MODIFY...'
  cs.select { |c| %i[string text].include? c.type }.each do |c|
    puts "    #{c.name}"
    ActiveRecord::Base.connection.execute "ALTER TABLE `#{t}` MODIFY `#{c.name}` #{c.sql_type} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  end
end

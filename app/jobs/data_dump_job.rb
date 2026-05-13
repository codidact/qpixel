class DataDumpJob < ApplicationJob
  queue_as :default

  def perform(*args)
    permitted = YAML.safe_load(File.read(Rails.root.join('db/scripts/dump_permitted_columns.yml')))
    logger.info "Found #{permitted&.size} tables to dump."

    begin
      exec('SET FOREIGN_KEY_CHECKS = 0;')
      exec('DROP DATABASE qpixel_dump;')
      exec('CREATE DATABASE qpixel_dump;')

      @db_creds = Rails.configuration.database_configuration[Rails.env]
      @username = @db_creds['username']
      @password = @db_creds['password']
      @database = @db_creds['database']

      mysqldump_command = "mysqldump -u #{@username} -p#{@password} -d #{@database} --no-tablespaces"
      mysql_command = "mysql -u #{@username} -p#{@password} -D qpixel_dump"
      copy_success = system("#{mysqldump_command} | #{mysql_command}")

      unless copy_success
        logger.fatal "Couldn't replicate database: nonzero exit code"
        return
      end

      permitted&.each do |table, data|
        migrate_table(table, data)
      end

      # Export backup DB to file
      # Upload dump somewhere
      # Create Dump record
      # Delete backup DB
    ensure
      exec('SET FOREIGN_KEY_CHECKS = 1;')
    end
  end

  def migrate_table(table, data)
    columns = data['columns']
    query = data['query']
    select = "(SELECT #{columns.map { |c| "`#{table}`.`#{c}`" }.join(', ')} FROM #{@database}.#{table} #{query})"
    full_query = "INSERT INTO qpixel_dump.`#{table}` (#{columns.map { |c| "`#{c}`" }.join(', ')}) #{select}"
    logger.debug full_query
    exec(full_query)
  end

  def exec(sql)
    ApplicationRecord.connection.execute(sql)
  end
end

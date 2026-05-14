class DataDumpJob < ApplicationJob
  queue_as :default

  def perform(drop_db_after: true)
    permitted = YAML.safe_load_file(Rails.root.join('db/scripts/dump_permitted_columns.yml'))
    logger.info "Found #{permitted&.size} tables to dump."

    begin
      exec('SET FOREIGN_KEY_CHECKS = 0;')
      exec('DROP DATABASE IF EXISTS qpixel_dump;')
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

      logger.info 'Copied database structure.'

      permitted&.each do |table, data|
        migrate_table(table, data)
      end

      logger.info 'Migrated data.'

      file_path = Rails.root.join('tmp/qpixel_export.sql')
      export_cmd = "mysqldump -u #{@username} -p#{@password} qpixel_dump --no-tablespaces > #{file_path}"
      export_success = system(export_cmd)

      unless export_success
        logger.fatal "Couldn't export database: nonzero exit code"
        return
      end

      logger.info 'Exported database.'

      dump = Dump.create(title: "Data Dump #{Time.now.strftime('%Y-%m-%d')}",
                         comment: "Automatically generated data dump as of #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}.",
                         file: File.open(file_path),
                         automatic: true)
      Dump.where(automatic: true).where.not(id: dump.id).destroy_all
    ensure
      exec('SET FOREIGN_KEY_CHECKS = 1;')
      if drop_db_after
        exec('DROP DATABASE qpixel_dump;')
      end
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

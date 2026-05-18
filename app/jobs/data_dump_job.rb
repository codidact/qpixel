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
      @port = @db_creds['port']
      @host = @db_creds['host']

      mysqldump_command = build_command('mysqldump', '-h', @host, '-u', @username, "-p#{@password}", @database,
                                        '--no-tablespaces', "--port=#{@port}", ssl_state)
      mysql_command = build_command('mysql', '-h', @host, '-u', @username, "-p#{@password}", "--port=#{@port}",
                                    '-D', 'qpixel_dump', ssl_state)
      logger.debug 'Running system command:'
      logger.debug "#{mysqldump_command} | #{mysql_command}"
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
      export_cmd = build_command('mysqldump', '-h', @host, '-u', @username, "-p#{@password}", "--port=#{@port}",
                                 'qpixel_dump', '--no-tablespaces', ssl_state, '>', file_path)
      logger.debug 'Running system command:'
      logger.debug export_cmd
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
    rescue ActiveRecord::ConnectionFailed
      logger.fatal "Couldn't connect to database. Have you run `GRANT ALL ON qpixel_dump.*` for your DB user?"
    ensure
      exec('SET FOREIGN_KEY_CHECKS = 1;')
      if drop_db_after
        exec('DROP DATABASE qpixel_dump;')
      end
    end
  end

  private

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

  def build_command(cmd, *args)
    "#{cmd} #{args.join(' ')}"
  end

  def ssl_state
    "--ssl-mode=#{Rails.env.development? ? 'DISABLED' : 'PREFERRED'}"
  end
end

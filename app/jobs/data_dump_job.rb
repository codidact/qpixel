class DataDumpJob < ApplicationJob
  queue_as :default

  def perform(*args)
    permitted = YAML.safe_load(File.read(Rails.root.join('db/scripts/dump_permitted_columns.yml')))
    logger.info "Found #{permitted&.size} tables to dump."

    # Create backup database
    # Mirror DB structure (mysqldump | mysql?)

    permitted&.each do |table, data|
      results = pull_table_data(table, data)
    end

    # Dump all of the results into the backup DB
    # Export backup DB to file
    # Upload dump somewhere
    # Create Dump record
    # Delete backup DB
  end

  def pull_table_data(table, data)
    columns = data['columns']
    query = data['query']
    full_query = "SELECT #{columns.map { |c| "#{table}.#{c}" }.join(', ')} FROM #{table} #{query}"
    logger.debug full_query
    ApplicationRecord.connection.execute(full_query).to_a
  end
end

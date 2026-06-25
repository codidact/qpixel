class DatabaseBackupJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    storage = backup_storage

    return unless backup_storage

    timestamp = `date +%s`.strip
    backup_location = AppConfig.server_settings['db_backups_path']
    filename = "#{backup_location}/qpixel-#{timestamp}.sql"
    db_creds = Rails.configuration.database_configuration[Rails.env]
    mysqldump_command = build_command 'mysqldump', '-h', db_creds['host'], "--port=#{db_creds['port']}", '-u',
                                      db_creds['username'], "-p#{db_creds['password']}", db_creds['database'], '>',
                                      filename
    logger.debug 'Running system command:'
    logger.debug mysqldump_command
    system mysqldump_command
    file_name_only = "qpixel-#{timestamp}.sql"
    storage.upload(file_name_only, File.open(filename), filename: file_name_only,
                   content_type: 'application/sql')
  end

  private

  def backup_storage
    registry = ActiveStorage::Blob.services
    registry.fetch :db_backup
  rescue KeyError
    logger.fatal 'Database backup storage is not configured. Add a :db_backup configuration to config/storage.yml.'
    nil
  end

  def build_command(cmd, *args)
    "#{cmd} #{args.compact_blank.join(' ')}"
  end
end

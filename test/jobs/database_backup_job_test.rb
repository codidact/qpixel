require 'test_helper'

class DatabaseBackupJobTest < ActiveJob::TestCase
  setup do
    AppConfig.server_settings['db_backups_path'] = backup_dirname
    File.delete(*backup_basenames.map { |basename| backup_dirname.join(basename) })
  end

  test 'job runs successfully' do
    perform_enqueued_jobs do
      DatabaseBackupJob.perform_later
    end
    assert_performed_jobs 1

    backups = backup_basenames

    assert_equal 1, backups.length
  end

  private

  def backup_dirname
    Rails.root.join('tmp/storage')
  end

  def backup_basenames
    Dir.glob('qpixel-*.sql', base: backup_dirname)
  end
end

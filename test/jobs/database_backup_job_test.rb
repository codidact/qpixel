require 'test_helper'

class DatabaseBackupJobTest < ActiveJob::TestCase
  setup do
    base_path = backup_dirname
    AppConfig.server_settings['db_backups_path'] = base_path
    Dir.mkdir(base_path) unless Dir.exist?(base_path)
    File.delete(*backup_basenames.map { |basename| base_path.join(basename) })
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

require 'test_helper'

class DataDumpJobTest < ActiveJob::TestCase
  setup :i_know_better_than_activerecord
  teardown :i_dont_know_better_than_activerecord

  test 'job runs successfully' do
    perform_enqueued_jobs do
      DataDumpJob.perform_later
    end
    assert_performed_jobs 1
  end

  test 'no excluded data present in final dump DB' do
    perform_enqueued_jobs do
      DataDumpJob.perform_later(drop_db_after: false)
    end

    conn = ApplicationRecord.connection
    all_columns = conn.tables.to_h { |t| [t, conn.columns(t).map(&:name)] }
    permitted = YAML.safe_load_file(Rails.root.join('db/scripts/dump_permitted_columns.yml'))
    excluded_cols = all_columns.to_h do |t, cols|
      [
        t,
        cols.reject { |c| permitted.include?(t) && permitted[t]['columns'].include?(c) }
      ]
    end.reject { |_t, cols| cols.empty? }

    excluded_cols.each do |table, cols|
      query = "SELECT #{cols.map { |c| "`#{c}`" }.join(', ')} FROM qpixel_dump.`#{table}`"
      results = conn.execute(query).to_a
      results.transpose.each.with_index do |col, i|
        # EITHER all values in the column should be nil, OR all values in the column should be identical (which implies
        # a default value was applied), for us to be happy that there is no true data in the column.
        assert col.all?(&:nil?) || col.uniq.size <= 1, "Distinct non-null data present in column `#{table}`.`#{cols[i]}`"
      end
    end
  end

  private

  ##
  # This is definitely not a terrible idea that will come back to bite me later on.
  # For context, this is necessary because the +create+ call in DataDumpJob is run by ActiveRecord in a transaction
  # (well, ish - using savepoints). However, the DDL modifications that the data dump performs automatically release
  # the savepoints, which then causes the RELEASE query to fail. I think. There's no convenient way to have AR not run
  # the +create+ call in a transaction, so we have to monkeypatch it out.
  def i_know_better_than_activerecord
    ActiveRecord::ConnectionAdapters::Mysql2Adapter.class_eval do
      def begin_db_transaction(*)
      end

      def commit_db_transaction(*)
      end

      def create_savepoint(*)
      end

      def rollback_to_savepoint(*)
      end

      def release_savepoint(*)
      end
    end
  end

  ##
  # Let's not let the terrible idea affect everything else too.
  def i_dont_know_better_than_activerecord
    $LOADED_FEATURES.delete_if { |f| f.include?('mysql2_adapter') }
    unless require 'active_record/connection_adapters/mysql2_adapter'
      Rails.logger.warn "Couldn't re-require mysql2 adapter. Everything after this point will not run in transactions."
    end
  end
end

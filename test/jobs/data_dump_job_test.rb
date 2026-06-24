require 'test_helper'

class DataDumpJobTest < ActiveJob::TestCase
  self.use_transactional_tests = false

  test 'job runs successfully' do
    perform_enqueued_jobs do
      DataDumpJob.perform_later
    end
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
    end
    excluded_cols = excluded_cols.reject { |_t, cols| cols.empty? }

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
end

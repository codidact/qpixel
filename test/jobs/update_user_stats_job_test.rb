require 'test_helper'

class UpdateUserStatsJobTest < ActiveJob::TestCase
  test 'job runs without errors' do
    perform_enqueued_jobs do
      UpdateUserStatsJob.perform_later
    end
  end
end

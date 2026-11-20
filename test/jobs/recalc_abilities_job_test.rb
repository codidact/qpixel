require 'test_helper'

class RecalcAbilitiesJobTest < ActiveJob::TestCase
  test 'should run job successfully' do
    perform_enqueued_jobs do
      RecalcAbilitiesJob.perform_later(verbose: false, quiet: true)
    end
    assert_performed_jobs 1
  end
end

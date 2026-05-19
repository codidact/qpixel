class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  def initialize(*args, **opts)
    @job_id = SecureRandom.uuid
    super
  end

  # Executes a given SQL statement in the context of the current connection
  # @param [String] sql SQL statement to execute
  def exec(sql)
    ApplicationRecord.connection.execute(sql)
  end

  def logger
    Rails.job_logger.tagged(self.class.name, @job_id)
  end
end

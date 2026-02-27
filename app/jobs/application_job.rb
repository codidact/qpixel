class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  def initialize
    @job_id = SecureRandom.uuid
    super
  end

  def logger
    Rails.job_logger.tagged(self.class.name, @job_id)
  end
end

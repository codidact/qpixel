module Rails
  class << self
    @job_logger = nil

    def job_logger
      if @job_logger.nil?
        logger = ActiveSupport::Logger.new(Rails.root.join('log/jobs.log'))
        logger.level = ActiveSupport::Logger::INFO
        logger.formatter = ::Logger::Formatter.new
        @job_logger = ActiveSupport::TaggedLogging.new(logger)
      else
        @job_logger
      end
    end
  end
end

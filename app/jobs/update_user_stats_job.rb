class UpdateUserStatsJob < ApplicationJob
  queue_as :default

  def perform(*)
    domains = User.all.select(:email)
                  .group_by { |u| u.email&.split('@')[1] }
                  .to_h { |d, u| [d, u.size] }
                  .reject { |d, _u| d.include? 'localhost' }
    Rails.cache.hmset('user_email_domains', domains)
  end
end

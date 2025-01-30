# frozen_string_literal: true

module Maintenance
  class InitializeUserWebsitesTask < MaintenanceTasks::Task
    def collection
      # Collection to be iterated over
      # Must be Active Record Relation or Array
      User.all
    end

    def process(user)
      # The work to be done in a single iteration of the task.
      # This should be idempotent, as the same element may be processed more
      # than once if the task is interrupted and resumed.
      unless user.user_websites.where(user_id: user.id, position: 1).size.positive?
        if user.website.present?
          UserWebsite.create!(user_id: user.id, position: 1, label: 'website', url: user.website)
        else
          UserWebsite.create!(user_id: user.id, position: 1)
        end
      end
      unless user.user_websites.where(user_id: user.id, position: 2).size.positive?
        if user.twitter.present?
          UserWebsite.create!(user_id: user.id, position: 2, label: 'Twitter',
                              url: "https://twitter.com/#{user.twitter}")
        else
          UserWebsite.create!(user_id: user.id, position: 2)
        end
      end
      # This check *should* be superfluous, but just in case...
      unless user.user_websites.where(user_id: user.id, position: 3).size.positive?
        UserWebsite.create!(user_id: user.id, position: 3)
      end
    end

    def count
      # Optionally, define the number of rows that will be iterated over
      # This is used to track the task's progress
    end
  end
end

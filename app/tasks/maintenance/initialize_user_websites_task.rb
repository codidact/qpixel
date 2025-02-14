# frozen_string_literal: true

module Maintenance
  class InitializeUserWebsitesTask < MaintenanceTasks::Task
    def collection
      User.all
    end

    def process(user)
      unless user.user_websites.exists?(position: 1)
        if user.website.present?
          UserWebsite.create!(user_id: user.id, position: 1, label: 'website', url: user.website)
        else
          UserWebsite.create!(user_id: user.id, position: 1)
        end
      end

      unless user.user_websites.exists?(position: 2)
        if user.twitter.present?
          UserWebsite.create!(user_id: user.id, position: 2, label: 'Twitter',
                              url: "https://twitter.com/#{user.twitter}")
        else
          UserWebsite.create!(user_id: user.id, position: 2)
        end
      end

      # This check *should* be superfluous, but just in case...
      unless user.user_websites.exists?(position: 3)
        UserWebsite.create!(user_id: user.id, position: 3)
      end
    end
  end
end

class ModWarningController < ApplicationController
    before_action :authenticate_user!
    
    def current
        @warning = ModWarning.where(community_user: current_user.community_user, active: true).last
        @warning_message_html = helpers.render_markdown(@warning.body)
        
        return not_found if @warning.nil?

        render layout: 'without_sidebar'
    end
end

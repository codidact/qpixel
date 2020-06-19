class ModWarningController < ApplicationController
    before_action :authenticate_user!
    before_action :set_warning

    def current
        render layout: 'without_sidebar'
    end

    def approve
        return not_found if @warning.is_suspension && @warning.suspension_active?

        if params[:approve_checkbox].nil?
            @failed_to_click_checkbox = true
            return render 'current', layout: 'without_sidebar'
        end

        @warning.update(active: false)
        redirect_to(root_path)
    end

    private

    def set_warning
        @warning = ModWarning.where(community_user: current_user.community_user, active: true).last
        @warning_message_html = helpers.render_markdown(@warning.body)
        not_found if @warning.nil?
    end
end

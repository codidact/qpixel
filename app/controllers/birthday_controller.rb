class BirthdayController < ApplicationController
    def index
        render layout: 'without_sidebar'
    end
end

class TourController < ApplicationController
    def index
        render layout: 'without_sidebar'
    end

    def question1
        render layout: 'without_sidebar'
    end

    def question2
        render layout: 'without_sidebar'
    end

    def question3
        render layout: 'without_sidebar'
    end

    def more
        @communities = Community.all
        render layout: 'without_sidebar'
    end

    def end
        render layout: 'without_sidebar'
    end
end

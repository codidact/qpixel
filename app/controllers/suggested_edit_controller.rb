class SuggestedEditController < ApplicationController
    #require 'redcarpet/render_strip'
    before_action :set_suggested_edit, only: [:show]

    #@@plain_renderer = Redcarpet::Markdown.new(Redcarpet::Render::StripDown.new)

    #def self.renderer
    #    @@plain_renderer
    #end

    def show
        render layout: 'without_sidebar'
    end

    def set_suggested_edit
        @edit = SuggestedEdit.find(params[:id])
    end
end

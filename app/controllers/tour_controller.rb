class TourController < ApplicationController
  layout 'without_sidebar'

  def index; end

  def question1; end

  def question2
    @tagset_id = TagSet.find_by(name: 'Tour')&.id || -1
  end

  def question3; end

  def more
    @communities = Community.all
  end

  def end; end
end

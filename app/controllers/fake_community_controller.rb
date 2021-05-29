class FakeCommunityController < ApplicationController
  def communities
    @communities = Community.all
    render layout: 'without_sidebar'
  end
end

class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index privacy_policy unsolvable_cell_notice substack_article utility_man_screenshots fantasy_kings_screenshots ]

  def index
  end

  def privacy_policy
  end

  def unsolvable_cell_notice
  end

  def substack_article
  end

  def utility_man_screenshots
  end

  def fantasy_kings_screenshots
  end
end
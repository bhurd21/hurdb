class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index privacy_policy unsolvable_cell_notice substack_article ]
  
  def index
  end
  
  def privacy_policy
  end

  def unsolvable_cell_notice
  end

  def substack_article
  end
end
class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index privacy_policy unsolvable_cell_notice substack_article resume ]
  
  def index
  end
  
  def privacy_policy
  end

  def unsolvable_cell_notice
  end

  def substack_article
  end

  def resume
  end
end
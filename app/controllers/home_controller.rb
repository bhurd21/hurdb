class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index privacy_policy ]
  
  def index
  end
  
  def privacy_policy
  end
end
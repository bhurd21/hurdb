class Batting < ApplicationRecord
  belongs_to :person, foreign_key: :player_id, primary_key: :player_id
  
  # Alias attributes to match original column names from MySQL
  alias_attribute :'2B', :doubles
  alias_attribute :'3B', :triples
  
  # For easier access in queries
  def double_b
    doubles
  end
  
  def triple_b
    triples
  end
end

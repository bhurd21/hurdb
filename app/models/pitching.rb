class Pitching < ApplicationRecord
  belongs_to :person, foreign_key: :player_id, primary_key: :player_id
  
  # Calculate innings pitched from IPouts (outs pitched)
  def ip
    return 0 if ip_outs.nil?
    ip_outs / 3.0
  end
end

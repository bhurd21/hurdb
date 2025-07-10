module Questions::Concerns::PlayerExtractor
  extend ActiveSupport::Concern

  private

  def extract_player_info(player_condition)
    player_where = player_lookup[player_condition]
    return nil unless player_where
    
    {
      condition: player_condition,
      where_clause: player_where
    }
  end

  def player_lookup
    DataLookupHelper.player_lookup
  end
end

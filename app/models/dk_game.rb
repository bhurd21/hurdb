class DkGame < DkBaseRecord
  self.table_name = ENV.fetch('TABLE_NAME', 'dk_games')
  
  # Map the actual PostgreSQL columns to the betting format expected by the UI
  def to_bet_format(bet_id = nil)
    {
      id: bet_id || id,
      home_team: home_team,
      away_team: away_team,
      date: formatted_date,
      home_spread: format_spread(home_spread_point),
      away_spread: format_spread(away_spread_point),
      total: total_point&.to_s,
      home_spread_odds: format_odds(home_spread_price),
      away_spread_odds: format_odds(away_spread_price),
      total_odds: format_odds(over_price), # Using over_price for total odds
      home_moneyline: format_odds(home_moneyline),
      away_moneyline: format_odds(away_moneyline),
      update_time: update_time
    }
  end
  
  private
  
  def formatted_date
    # Format the commence_time as a readable date
    if commence_time
      commence_time.strftime("%a %d %b")
    else
      "TBD"
    end
  end
  
  def format_spread(spread_value)
    return nil unless spread_value
    spread_value > 0 ? "+#{spread_value}" : spread_value.to_s
  end
  
  def format_odds(odds_value)
    return nil unless odds_value
    odds_value > 0 ? "+#{odds_value}" : odds_value.to_s
  end
end

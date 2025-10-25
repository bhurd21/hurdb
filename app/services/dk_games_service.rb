class DkGamesService
  class << self
    def fetch_games(limit: 20)
      return mock_data unless postgresql_available?
      
      DkGame.limit(limit).order(:id).map.with_index do |game, index|
        game.to_bet_format(index + 1)
      end
    rescue => e
      Rails.logger.error "Error fetching DK Games: #{e.message}"
      mock_data
    end
    
    private
    
    def postgresql_available?
      @postgresql_available ||= begin
        # Check if environment variables are present first
        return false unless ENV['DB_HOST'].present? && ENV['DB_NAME'].present?
        
        DkGame.connection.execute("SELECT 1")
        true
      rescue
        false
      end
    end
    
    def mock_data
      [
        {
          id: 3,
          home_team: "KC Chiefs",
          away_team: "LAR Rams",
          date: "Sun 19 Oct", 
          home_spread: "-3.5",
          away_spread: "+3.5",
          total: "48.5",
          home_spread_odds: "-110",
          away_spread_odds: "110",
          total_odds: "-105",
          home_moneyline: "-180",
          away_moneyline: "+180"
        }
      ]
    end
  end
end

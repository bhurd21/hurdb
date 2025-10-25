class BetsController < ApplicationController
  allow_unauthenticated_access only: %i[ index create ]
  def index
    # Initialize staged bets (in real app this would be in session or database)
    session[:staged_bets] ||= []
    
    # Fetch data from PostgreSQL DK Games database via service
    @bets = DkGamesService.fetch_games(limit: 1000)
    
    @staged_bets = session[:staged_bets]
  end
  
  def create
    selected_bet = params[:selected_bet]
    
    if selected_bet.present?
      # Parse the selected bet string: "bet_id_team_bet_type"
      parts = selected_bet.split('_')
      bet_id = parts[0]
      team = parts[1] # 'home' or 'away'
      bet_type = parts[2..-1].join('_') # 'spread', 'winner', 'total_over', 'total_under'
      
      Rails.logger.info "=== BET CONFIRMED ==="
      Rails.logger.info "Bet ID: #{bet_id}"
      Rails.logger.info "Team: #{team}"
      Rails.logger.info "Bet Type: #{bet_type}"
      Rails.logger.info "===================="
      
      redirect_to bets_path, notice: "Bet confirmed: #{team} #{bet_type} (ID: #{bet_id})"
    else
      redirect_to bets_path, alert: "Please select a bet before confirming"
    end
  end
  
  def stage_bet
    bet_id = params[:bet_id].to_i
    bet_type = params[:bet_type] # 'spread', 'total', or 'moneyline'
    
    session[:staged_bets] ||= []
    session[:staged_bets] << { bet_id: bet_id, bet_type: bet_type }
    
    render json: { 
      success: true, 
      message: "Bet #{bet_id} (#{bet_type}) added to staged bets!",
      staged_count: session[:staged_bets].length
    }
  end
end

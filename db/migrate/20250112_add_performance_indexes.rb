class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Critical indexes for appearances table
    add_index :appearances, :player_id
    add_index :appearances, :team_id
    add_index :appearances, :year_id
    add_index :appearances, [:player_id, :team_id]
    add_index :appearances, [:team_id, :year_id]
    
    # Critical indexes for teams table
    add_index :teams, :team_id
    add_index :teams, :year_id
    add_index :teams, [:team_id, :year_id]
    add_index :teams, :ws_win
    
    # Critical indexes for people table
    add_index :people, :player_id
    add_index :people, :hall_of_fame
    add_index :people, :is_ws_champ
    add_index :people, :matches_only_one_team
    
    # Critical indexes for other tables
    add_index :hall_of_fames, :player_id
    add_index :hall_of_fames, [:voted_by, :inducted]
    add_index :battings, :player_id
    add_index :battings, :team_id
    add_index :pitchings, :player_id
    add_index :pitchings, :team_id
    add_index :awards_players, :player_id
    add_index :all_star_fulls, :player_id
  end
end

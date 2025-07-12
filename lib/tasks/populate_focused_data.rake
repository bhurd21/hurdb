namespace :baseball do
  desc "Populate focused baseball data with detailed logging"
  task populate_focused: :environment do
    puts "=" * 60
    puts "STARTING FOCUSED BASEBALL DATA POPULATION"
    puts "=" * 60
    puts "Started at: #{Time.current}"
    
    total_start = Time.current
    
    # Task 1: Hall of Fame
    puts "\n1. Populating Hall of Fame status..."
    start_time = Time.current
    hall_of_fame_players = HallOfFame.where(voted_by: 'BBWAA', inducted: 'Y')
                                    .distinct
                                    .pluck(:player_id)
    puts "   Found #{hall_of_fame_players.count} Hall of Fame players"
    updated_count = Person.where(player_id: hall_of_fame_players).update_all(hall_of_fame: true)
    puts "   Updated #{updated_count} players with Hall of Fame status"
    puts "   Completed in #{(Time.current - start_time).round(2)} seconds"
    
    # Task 2: World Series Champions
    puts "\n2. Populating World Series champion status..."
    start_time = Time.current
    sql = <<~SQL
      SELECT DISTINCT a.player_id
      FROM appearances a
      JOIN teams t ON a.team_id = t.team_id AND a.year_id = t.year_id
      WHERE t.ws_win = 'Y'
    SQL
    results = ActiveRecord::Base.connection.execute(sql)
    ws_champ_players = results.map { |row| row['player_id'] }
    puts "   Found #{ws_champ_players.count} World Series champion players"
    updated_count = Person.where(player_id: ws_champ_players).update_all(is_ws_champ: true)
    puts "   Updated #{updated_count} players with World Series champion status"
    puts "   Completed in #{(Time.current - start_time).round(2)} seconds"
    
    # Task 3: Only One Team
    puts "\n3. Populating 'only one team' status..."
    start_time = Time.current
    sql = <<~SQL
      WITH player_team_counts AS (
        SELECT 
          player_id,
          lg_id,
          COUNT(DISTINCT team_id) as team_count
        FROM appearances
        GROUP BY player_id, lg_id
      ),
      player_league_summary AS (
        SELECT 
          player_id,
          SUM(CASE WHEN lg_id = 'AL' AND team_count = 1 THEN 1 ELSE 0 END) as al_one_team,
          SUM(CASE WHEN lg_id = 'NL' AND team_count = 1 THEN 1 ELSE 0 END) as nl_one_team,
          SUM(CASE WHEN team_count > 1 THEN 1 ELSE 0 END) as multiple_teams_any_league
        FROM player_team_counts
        GROUP BY player_id
      )
      SELECT player_id
      FROM player_league_summary
      WHERE multiple_teams_any_league = 0
        AND NOT (al_one_team = 1 AND nl_one_team = 1)
    SQL
    results = ActiveRecord::Base.connection.execute(sql)
    only_one_team_players = results.map { |row| row['player_id'] }
    puts "   Found #{only_one_team_players.count} players who played for only one team"
    updated_count = Person.where(player_id: only_one_team_players).update_all(matches_only_one_team: true)
    puts "   Updated #{updated_count} players with 'only one team' status"
    puts "   Completed in #{(Time.current - start_time).round(2)} seconds"
    
    # Task 4: No Hitters
    puts "\n4. Populating no-hitter status..."
    start_time = Time.current
    csv_file = Rails.root.join('db', 'csv', 'no_hitters_data.csv')
    
    if File.exist?(csv_file)
      no_hitter_players = []
      CSV.foreach(csv_file, headers: true) do |row|
        no_hitter_players << row['has_no_hitter'] if row['has_no_hitter']
      end
      puts "   Found #{no_hitter_players.count} no-hitter players from CSV"
      updated_count = Person.where(player_id: no_hitter_players).update_all(has_no_hitter: true)
      puts "   Updated #{updated_count} players with no-hitter status"
    else
      puts "   CSV file not found: #{csv_file}"
    end
    puts "   Completed in #{(Time.current - start_time).round(2)} seconds"
    
    # Task 5: 6+ WAR Seasons
    puts "\n5. Populating 6+ WAR season status..."
    start_time = Time.current
    csv_file = Rails.root.join('db', 'csv', 'war_leaderboard_data.csv')
    
    if File.exist?(csv_file)
      six_war_players = []
      CSV.foreach(csv_file, headers: true) do |row|
        if row['is_6_war_season'] == 'True'
          six_war_players << row['playerID']
        end
      end
      puts "   Found #{six_war_players.uniq.count} 6+ WAR season players from CSV"
      updated_count = Person.where(player_id: six_war_players.uniq).update_all(has_6_war_season: true)
      puts "   Updated #{updated_count} players with 6+ WAR season status"
    else
      puts "   CSV file not found: #{csv_file}"
    end
    puts "   Completed in #{(Time.current - start_time).round(2)} seconds"
    
    total_time = Time.current - total_start
    
    puts "\n" + "=" * 60
    puts "FOCUSED BASEBALL DATA POPULATION COMPLETED"
    puts "=" * 60
    puts "Total execution time: #{total_time.round(2)} seconds"
    puts "Completed at: #{Time.current}"
    puts "All tasks completed successfully!"
  end
end

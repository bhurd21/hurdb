require 'csv'
require 'activerecord-import'

namespace :baseball do
  BATCH_SIZE = 1000  # Process records in batches of 1000

  def import_csv_in_batches(model, csv_file, &block)
    return unless File.exist?(csv_file)
    
    puts "Importing #{model.name} data from CSV in batches of #{BATCH_SIZE}..."
    
    records = []
    total_imported = 0
    
    CSV.foreach(csv_file, headers: true).with_index(1) do |row, index|
      record = yield(row, model)
      records << record if record
      
      if records.size >= BATCH_SIZE
        model.import records
        total_imported += records.size
        puts "Imported batch: #{total_imported} records so far..."
        records = []
        
        # Add a small sleep to prevent CPU overload
        sleep(0.1) if total_imported % (BATCH_SIZE * 10) == 0
      end
    end
    
    # Import any remaining records
    if records.any?
      model.import records
      total_imported += records.size
    end
    
    puts "Imported #{total_imported} #{model.name} records successfully!"
  end

  desc "Populate baseball data from CSV files"
  task populate_all: :environment do
    Rake::Task['baseball:populate_all_star_fulls'].invoke
    Rake::Task['baseball:populate_appearances'].invoke
    Rake::Task['baseball:populate_awards_players'].invoke
    Rake::Task['baseball:populate_people'].invoke
    Rake::Task['baseball:populate_battings'].invoke
    Rake::Task['baseball:populate_hall_of_fames'].invoke
    Rake::Task['baseball:populate_pitchings'].invoke
    Rake::Task['baseball:populate_teams'].invoke
    Rake::Task['baseball:populate_primary_positions'].invoke
    Rake::Task['baseball:populate_hall_of_fame'].invoke
    Rake::Task['baseball:populate_ws_champs'].invoke
    Rake::Task['baseball:populate_only_one_team'].invoke
    Rake::Task['baseball:populate_no_hitters'].invoke
    Rake::Task['baseball:populate_6_war_seasons'].invoke
  end

  desc "Populate AllStarFull data from CSV"
  task populate_all_star_fulls: :environment do
    model = AllStarFull
    csv_file = Rails.root.join('db', 'csv', 'AllStarFull.csv')
    
    if model.exists?
      puts "#{model.name} already has data (#{model.count} records). Skipping import."
      next
    end
    
    if File.exist?(csv_file)
      import_csv_in_batches(model, csv_file) do |row, model|
        model.new(
          player_id: row['playerID'],
          year_id: row['yearID']&.to_i,
          game_num: row['gameNum']&.to_i,
          game_id: row['gameID'],
          team_id: row['teamID'],
          lg_id: row['lgID'],
          gp: row['GP']&.to_i,
          starting_pos: row['startingPos']
        )
      end
    else
      puts "CSV file not found: #{csv_file}"
    end
  end

  desc "Populate Appearances data from CSV"
  task populate_appearances: :environment do
    model = Appearance
    csv_file = Rails.root.join('db', 'csv', 'Appearances.csv')
    
    if model.exists?
      puts "#{model.name} already has data (#{model.count} records). Skipping import."
      next
    end
    
    if File.exist?(csv_file)
      import_csv_in_batches(model, csv_file) do |row, model|
        model.new(
          year_id: row['yearID']&.to_i,
          team_id: row['teamID'],
          lg_id: row['lgID'],
          player_id: row['playerID'],
          g_all: row['G_all']&.to_i,
          gs: row['GS']&.to_f,
          g_batting: row['G_batting']&.to_i,
          g_defense: row['G_defense']&.to_f,
          g_p: row['G_p']&.to_i,
          g_c: row['G_c']&.to_i,
          g_1b: row['G_1b']&.to_i,
          g_2b: row['G_2b']&.to_i,
          g_3b: row['G_3b']&.to_i,
          g_ss: row['G_ss']&.to_i,
          g_lf: row['G_lf']&.to_i,
          g_cf: row['G_cf']&.to_i,
          g_rf: row['G_rf']&.to_i,
          g_of: row['G_of']&.to_i,
          g_dh: row['G_dh']&.to_f,
          g_ph: row['G_ph']&.to_f,
          g_pr: row['G_pr']&.to_f
        )
      end
    else
      puts "CSV file not found: #{csv_file}"
    end
  end

  desc "Populate AwardsPlayers data from CSV"
  task populate_awards_players: :environment do
    model = AwardsPlayer
    csv_file = Rails.root.join('db', 'csv', 'AwardsPlayers.csv')
    
    if model.exists?
      puts "#{model.name} already has data (#{model.count} records). Skipping import."
      next
    end
    
    if File.exist?(csv_file)
      import_csv_in_batches(model, csv_file) do |row, model|
        model.new(
          player_id: row['playerID'],
          award_id: row['awardID'],
          year_id: row['yearID']&.to_i,
          lg_id: row['lgID'],
          tie: row['tie'],
          notes: row['notes']
        )
      end
    else
      puts "CSV file not found: #{csv_file}"
    end
  end

  desc "Populate People data from CSV"
  task populate_people: :environment do
    model = Person
    csv_file = Rails.root.join('db', 'csv', 'People.csv')
    
    if model.exists?
      puts "#{model.name} already has data (#{model.count} records). Skipping import."
      next
    end
    
    if File.exist?(csv_file)
      import_csv_in_batches(model, csv_file) do |row, model|
        model.new(
          player_id: row['playerID'],
          birth_year: row['birthYear']&.to_f,
          birth_month: row['birthMonth']&.to_f,
          birth_day: row['birthDay']&.to_f,
          birth_city: row['birthCity'],
          birth_country: row['birthCountry'],
          birth_state: row['birthState'],
          death_year: row['deathYear'],
          death_month: row['deathMonth'],
          death_day: row['deathDay']&.to_f,
          death_country: row['deathCountry'],
          death_state: row['deathState'],
          death_city: row['deathCity'],
          name_first: row['nameFirst'],
          name_last: row['nameLast'],
          name_given: row['nameGiven'],
          weight: row['weight'],
          height: row['height'],
          bats: row['bats'],
          throws: row['throws'],
          debut: row['debut'],
          bbref_id: row['bbrefID'],
          final_game: row['finalGame'],
          retro_id: row['retroID']
        )
      end
    else
      puts "CSV file not found: #{csv_file}"
    end
  end

  desc "Populate Batting data from CSV"
  task populate_battings: :environment do
    model = Batting
    csv_file = Rails.root.join('db', 'csv', 'Batting.csv')
    
    if model.exists?
      puts "#{model.name} already has data (#{model.count} records). Skipping import."
      next
    end
    
    if File.exist?(csv_file)
      import_csv_in_batches(model, csv_file) do |row, model|
        model.new(
          player_id: row['playerID'],
          year_id: row['yearID']&.to_i,
          stint: row['stint']&.to_i,
          team_id: row['teamID'],
          lg_id: row['lgID'],
          g: row['G']&.to_i,
          g_batting: row['G_batting'],
          ab: row['AB']&.to_i,
          r: row['R']&.to_i,
          h: row['H']&.to_i,
          doubles: row['2B']&.to_i,
          triples: row['3B']&.to_i,
          hr: row['HR']&.to_i,
          rbi: row['RBI']&.to_f,
          sb: row['SB']&.to_f,
          cs: row['CS']&.to_f,
          bb: row['BB']&.to_i,
          so: row['SO']&.to_f,
          ibb: row['IBB']&.to_f,
          hbp: row['HBP']&.to_f,
          sh: row['SH']&.to_f,
          sf: row['SF']&.to_f,
          gidp: row['GIDP']&.to_f,
          g_old: row['G_old']
        )
      end
    else
      puts "CSV file not found: #{csv_file}"
    end
  end

  desc "Populate HallOfFame data from CSV"
  task populate_hall_of_fames: :environment do
    model = HallOfFame
    csv_file = Rails.root.join('db', 'csv', 'HallOfFame.csv')
    
    if model.exists?
      puts "#{model.name} already has data (#{model.count} records). Skipping import."
      next
    end
    
    if File.exist?(csv_file)
      import_csv_in_batches(model, csv_file) do |row, model|
        model.new(
          player_id: row['playerID'],
          year_id: row['yearid']&.to_i,
          voted_by: row['votedBy'],
          ballots: row['ballots']&.to_f,
          needed: row['needed']&.to_f,
          votes: row['votes']&.to_f,
          inducted: row['inducted'],
          category: row['category'],
          needed_note: row['needed_note']
        )
      end
    else
      puts "CSV file not found: #{csv_file}"
    end
  end

  desc "Populate Pitching data from CSV"
  task populate_pitchings: :environment do
    model = Pitching
    csv_file = Rails.root.join('db', 'csv', 'Pitching.csv')
    
    if model.exists?
      puts "#{model.name} already has data (#{model.count} records). Skipping import."
      next
    end
    
    if File.exist?(csv_file)
      import_csv_in_batches(model, csv_file) do |row, model|
        model.new(
          player_id: row['playerID'],
          year_id: row['yearID']&.to_i,
          stint: row['stint']&.to_i,
          team_id: row['teamID'],
          lg_id: row['lgID'],
          w: row['W']&.to_i,
          l: row['L']&.to_i,
          g: row['G']&.to_i,
          gs: row['GS']&.to_i,
          cg: row['CG']&.to_i,
          sho: row['SHO']&.to_i,
          sv: row['SV']&.to_i,
          ip_outs: row['IPouts']&.to_i,
          h: row['H']&.to_i,
          er: row['ER']&.to_i,
          hr: row['HR']&.to_i,
          bb: row['BB']&.to_i,
          so: row['SO']&.to_i,
          ba_opp: row['BAOpp']&.to_f,
          era: row['ERA']&.to_f,
          ibb: row['IBB']&.to_f,
          wp: row['WP']&.to_i,
          hbp: row['HBP']&.to_f,
          bk: row['BK']&.to_i,
          bfp: row['BFP']&.to_f,
          gf: row['GF']&.to_i,
          r: row['R']&.to_i,
          sh: row['SH']&.to_f,
          sf: row['SF']&.to_f,
          gidp: row['GIDP']&.to_f
        )
      end
    else
      puts "CSV file not found: #{csv_file}"
    end
  end

  desc "Populate Teams data from CSV"
  task populate_teams: :environment do
    model = Team
    csv_file = Rails.root.join('db', 'csv', 'Teams.csv')
    
    if model.exists?
      puts "#{model.name} already has data (#{model.count} records). Skipping import."
      next
    end
    
    if File.exist?(csv_file)
      import_csv_in_batches(model, csv_file) do |row, model|
        model.new(
          year_id: row['yearID']&.to_i,
          lg_id: row['lgID'],
          team_id: row['teamID'],
          franch_id: row['franchID'],
          div_id: row['divID'],
          rank: row['Rank']&.to_i,
          g: row['G']&.to_i,
          g_home: row['Ghome']&.to_f,
          w: row['W']&.to_i,
          l: row['L']&.to_i,
          div_win: row['DivWin'],
          wc_win: row['WCWin'],
          lg_win: row['LgWin'],
          ws_win: row['WSWin'],
          r: row['R']&.to_i,
          ab: row['AB']&.to_i,
          h: row['H']&.to_i,
          doubles: row['2B']&.to_i,
          triples: row['3B']&.to_i,
          hr: row['HR']&.to_i,
          bb: row['BB']&.to_i,
          so: row['SO']&.to_f,
          sb: row['SB']&.to_f,
          cs: row['CS']&.to_f,
          hbp: row['HBP']&.to_f,
          sf: row['SF']&.to_f,
          ra: row['RA']&.to_i,
          er: row['ER']&.to_i,
          era: row['ERA']&.to_f,
          cg: row['CG']&.to_i,
          sho: row['SHO']&.to_i,
          sv: row['SV']&.to_i,
          ip_outs: row['IPouts']&.to_i,
          ha: row['HA']&.to_i,
          hra: row['HRA']&.to_i,
          bba: row['BBA']&.to_i,
          soa: row['SOA']&.to_i,
          e: row['E']&.to_i,
          dp: row['DP']&.to_i,
          fp: row['FP']&.to_f,
          name: row['name'],
          park: row['park'],
          attendance: row['attendance']&.to_f,
          bpf: row['BPF']&.to_i,
          ppf: row['PPF']&.to_i,
          team_id_br: row['teamIDBR'],
          team_id_lahman45: row['teamIDlahman45'],
          team_id_retro: row['teamIDretro']
        )
      end
    else
      puts "CSV file not found: #{csv_file}"
    end
  end

  desc "Clear all baseball data"
  task clear_all: :environment do
    puts "Clearing all baseball data..."
    [AllStarFull, Appearance, AwardsPlayer, Batting, HallOfFame, Person, Pitching, Team].each do |model|
      count = model.count
      model.delete_all
      puts "Cleared #{count} #{model.name} records"
    end
    puts "All baseball data cleared!"
  end

  desc "Calculate and populate primary positions for players"
  task populate_primary_positions: :environment do
    puts "Calculating primary positions for players..."
    
    # Position columns to analyze (excluding g_all, gs, g_batting, g_defense, g_ph, g_pr)
    position_columns = %w[g_p g_c g_1b g_2b g_3b g_ss g_lf g_cf g_rf g_of g_dh]
    
    # Derive position mapping from columns by removing 'g_' prefix and upcasing
    position_mapping = position_columns.to_h { |col| [col, col.sub(/^g_/, '').upcase] }
    
    # Get all unique player_ids from appearances
    player_ids = Appearance.distinct.pluck(:player_id)
    puts "Processing #{player_ids.count} unique players..."
    
    updated_count = 0
    batch_size = 100
    
    player_ids.each_slice(batch_size) do |batch|
      # Build a hash to store primary positions for this batch
      primary_positions = {}
      
      batch.each do |player_id|
        # Sum up games played at each position for this player
        position_totals = {}
        
        # Get all appearance records for this player
        appearances = Appearance.where(player_id: player_id)
        
        position_columns.each do |column|
          total = appearances.sum(column.to_sym) || 0
          position_totals[column] = total
        end
        
        # Find the position with the maximum games played
        max_column = position_totals.max_by { |_, value| value }&.first
        
        if max_column && position_totals[max_column] > 0
          primary_positions[player_id] = position_mapping[max_column]
        end
      end
      
      # Update people records in batch
      primary_positions.each do |player_id, position|
        Person.where(player_id: player_id).update_all(primary_position: position)
        updated_count += 1
      end
      
      puts "Processed batch: #{updated_count} players updated so far..."
    end
    
    puts "Primary position calculation complete! Updated #{updated_count} players."
    
    # Display some statistics
    position_counts = Person.where.not(primary_position: nil).group(:primary_position).count
    puts "\nPrimary position distribution:"
    position_counts.sort_by { |_, count| -count }.each do |position, count|
      puts "  #{position}: #{count} players"
    end
  end

  desc "Match Baseball Reference WAR data to players using fuzzy name matching"
  task match_bwar_data: :environment do
    csv_file = Rails.root.join('db', 'csv', 'bbref_top1000_career_war.csv')
    
    unless File.exist?(csv_file)
      puts "CSV file not found: #{csv_file}"
      exit 1
    end
    
    # Define helper methods for name matching
    def normalize_name(name)
      name.downcase.strip.gsub(/[^a-z\s]/, '').squeeze(' ')
    end
    
    def calculate_similarity(str1, str2)
      str1_norm = normalize_name(str1)
      str2_norm = normalize_name(str2)
      
      # Exact match
      return 1.0 if str1_norm == str2_norm
      
      # Check for "Jr" or "Sr" suffix issues - be more conservative
      # If one name has "jr" and the other doesn't, they're likely father/son
      str1_has_suffix = str1_norm.include?('jr') || str1_norm.include?('sr') || str1_norm.include?('ii') || str1_norm.include?('iii')
      str2_has_suffix = str2_norm.include?('jr') || str2_norm.include?('sr') || str2_norm.include?('ii') || str2_norm.include?('iii')
      
      if str1_has_suffix != str2_has_suffix
        # Different suffix status - likely father/son, be very conservative
        # Only match if they're very similar after removing suffix
        base1 = str1_norm.gsub(/\b(jr|sr|ii|iii)\b/, '').strip
        base2 = str2_norm.gsub(/\b(jr|sr|ii|iii)\b/, '').strip
        return 0.75 if base1 == base2  # Lower score to stay below threshold
      end
      
      # Check if one contains the other (but only if neither has suffix issues)
      if str1_norm.include?(str2_norm) || str2_norm.include?(str1_norm)
        return 0.9
      end
      
      # Calculate simple character overlap
      chars1 = str1_norm.chars.sort
      chars2 = str2_norm.chars.sort
      overlap = (chars1 & chars2).length
      total_chars = [chars1.length, chars2.length].max
      
      overlap.to_f / total_chars
    end
    
    def find_best_match(csv_name, people_data, threshold = 0.85)
      best_match = nil
      best_score = 0.0
      
      people_data.each do |person|
        score = calculate_similarity(csv_name, person[:full_name])
        if score > best_score && score >= threshold
          best_match = person
          best_score = score
        end
      end
      
      { match: best_match, score: best_score }
    end
    
    people_data = Person.all.map do |person|
      {
        id: person.id,
        player_id: person.player_id,
        full_name: person.full_name,
        name_first: person.name_first,
        name_last: person.name_last,
        bbref_id: person.bbref_id
      }
    end
    
    matched_count = 0
    unmatched_count = 0
    low_confidence_matches = []
    duplicate_matches = []
    bbref_id_matches = 0
    
    CSV.foreach(csv_file, headers: true) do |row|
      csv_name = "#{row['firstName']} #{row['lastName']}".strip
      war_value = row['war'].to_f
      
      # Strategy 1: Try exact bbref_id match
      last_name_part = row['lastName'].downcase.gsub(/[^a-z]/, '')[0,5]
      first_name_part = row['firstName'].downcase.gsub(/[^a-z]/, '')[0,2]
      bbref_id_candidate = "#{last_name_part}#{first_name_part}01"
      
      bbref_match = people_data.find { |p| p[:bbref_id] == bbref_id_candidate }
      
      if bbref_match
        person = Person.find(bbref_match[:id])
        if person.bwar_career.nil?
          person.update!(bwar_career: war_value)
          matched_count += 1
          bbref_id_matches += 1
        else
          duplicate_matches << { csv_name: csv_name, war: war_value, existing_player: person.full_name, existing_war: person.bwar_career }
        end
        next
      end
      
      # Strategy 2: Name-based matching
      match_result = find_best_match(csv_name, people_data, 0.85)
      
      if match_result[:match]
        person = Person.find(match_result[:match][:id])
        
        if person.bwar_career.nil?
          person.update!(bwar_career: war_value)
          matched_count += 1
        else
          duplicate_matches << { csv_name: csv_name, war: war_value, existing_player: person.full_name, existing_war: person.bwar_career }
        end
      else
        low_threshold_match = find_best_match(csv_name, people_data, 0.6)
        
        if low_threshold_match[:match]
          low_confidence_matches << { csv_name: csv_name, war: war_value, best_match: low_threshold_match[:match][:full_name], similarity: low_threshold_match[:score].round(3) }
        end
        unmatched_count += 1
      end
    end
    
    puts "Matched: #{matched_count} (#{bbref_id_matches} by ID, #{matched_count - bbref_id_matches} by name)"
    puts "Unmatched: #{unmatched_count}, Duplicates: #{duplicate_matches.size}"
    puts "Total with BWAR: #{Person.where.not(bwar_career: nil).count}"
  end

  desc "Fix incorrectly matched father/son BWAR data"
  task fix_father_son_bwar: :environment do
    corrections = [
      { csv_name: "Cal Ripken Jr.", csv_war: 95.9, wrong_player_id: "ripkeca01", correct_player_id: "ripkeca99" },
      { csv_name: "Ken Griffey Jr.", csv_war: 83.8, wrong_player_id: "griffke01", correct_player_id: "griffke02" }
    ]
    
    corrections.each do |correction|
      wrong_player = Person.find_by(player_id: correction[:wrong_player_id])
      if wrong_player&.bwar_career == correction[:csv_war]
        wrong_player.update!(bwar_career: nil)
      end
      
      correct_player = Person.find_by(player_id: correction[:correct_player_id])
      if correct_player && correct_player.bwar_career.nil?
        correct_player.update!(bwar_career: correction[:csv_war])
      end
    end
    
    puts "Father/son corrections completed"
  end

  desc "Populate hall of fame status for players"
  task populate_hall_of_fame: :environment do
    puts "Populating hall of fame status for players..."
    
    # Find all players inducted into Hall of Fame by BBWAA
    hall_of_fame_players = HallOfFame.where(voted_by: 'BBWAA', inducted: 'Y').pluck(:player_id).uniq
    
    puts "Found #{hall_of_fame_players.count} Hall of Fame players"
    
    # Update people table
    updated_count = Person.where(player_id: hall_of_fame_players).update_all(hall_of_fame: true)
    
    puts "Updated #{updated_count} players with Hall of Fame status"
  end

  desc "Populate World Series champion status for players"
  task populate_ws_champs: :environment do
    puts "Populating World Series champion status for players..."
    
    # Find all players who were on World Series winning teams
    ws_champion_players = ActiveRecord::Base.connection.execute(<<~SQL).map { |row| row['player_id'] }
      SELECT DISTINCT a.player_id
      FROM appearances a
      JOIN teams t ON a.team_id = t.team_id AND a.year_id = t.year_id
      WHERE t.ws_win = 'Y'
    SQL
    
    puts "Found #{ws_champion_players.count} World Series champion players"
    
    # Update people table
    updated_count = Person.where(player_id: ws_champion_players).update_all(is_ws_champ: true)
    
    puts "Updated #{updated_count} players with World Series champion status"
  end

  desc "Populate World Series champion roster status for players"
  task populate_ws_champ: :environment do
    puts "Populating World Series champion roster status for players..."
    
    # Find all players who were on World Series winning teams using raw SQL
    sql = <<~SQL
      SELECT DISTINCT a.player_id
      FROM appearances a
      JOIN teams t ON a.team_id = t.team_id AND a.year_id = t.year_id
      WHERE t.ws_win = 'Y'
    SQL
    
    results = ActiveRecord::Base.connection.execute(sql)
    ws_champ_players = results.map { |row| row['player_id'] }
    
    puts "Found #{ws_champ_players.count} World Series champion roster players"
    
    # Update people table
    updated_count = Person.where(player_id: ws_champ_players).update_all(is_ws_champ: true)
    
    puts "Updated #{updated_count} players with World Series champion status"
  end

  desc "Populate 'only one team' status for players"
  task populate_only_one_team: :environment do
    puts "Populating 'only one team' status for players..."
    
    # Complex SQL to find players who played for only one team
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
      WHERE multiple_teams_any_league = 0  -- Never played for multiple teams in any league
        AND NOT (al_one_team = 1 AND nl_one_team = 1)  -- Exclude players who played for exactly 1 AL and 1 NL team
    SQL
    
    results = ActiveRecord::Base.connection.execute(sql)
    only_one_team_players = results.map { |row| row['player_id'] }
    
    puts "Found #{only_one_team_players.count} players who played for only one team"
    
    # Update people table
    updated_count = Person.where(player_id: only_one_team_players).update_all(matches_only_one_team: true)
    
    puts "Updated #{updated_count} players with 'only one team' status"
  end

  desc "Populate no-hitter status for players"
  task populate_no_hitters: :environment do
    puts "Populating no-hitter status for players..."
    
    csv_file = Rails.root.join('db', 'csv', 'no_hitters_data.csv')
    
    unless File.exist?(csv_file)
      puts "CSV file not found: #{csv_file}"
      next
    end
    
    # Read player IDs from CSV
    no_hitter_players = []
    CSV.foreach(csv_file, headers: true) do |row|
      no_hitter_players << row['has_no_hitter'] if row['has_no_hitter'].present?
    end
    
    puts "Found #{no_hitter_players.count} no-hitter players"
    
    # Update people table
    updated_count = Person.where(player_id: no_hitter_players).update_all(has_no_hitter: true)
    
    puts "Updated #{updated_count} players with no-hitter status"
  end

  desc "Populate 6+ WAR season status for players"
  task populate_6_war_seasons: :environment do
    puts "Populating 6+ WAR season status for players..."
    
    csv_file = Rails.root.join('db', 'csv', 'war_leaderboard_data.csv')
    
    unless File.exist?(csv_file)
      puts "CSV file not found: #{csv_file}"
      next
    end
    
    # Read player IDs who had 6+ WAR seasons
    six_war_players = []
    CSV.foreach(csv_file, headers: true) do |row|
      if row['is_6_war_season'] == 'True' && row['playerID'].present?
        six_war_players << row['playerID']
      end
    end
    
    # Get unique players
    six_war_players = six_war_players.uniq
    
    puts "Found #{six_war_players.count} players with 6+ WAR seasons"
    
    # Update people table
    updated_count = Person.where(player_id: six_war_players).update_all(has_6_war_season: true)
    
    puts "Updated #{updated_count} players with 6+ WAR season status"
  end

  desc "Populate all new player condition statuses"
  task populate_player_conditions: :environment do
    Rake::Task['baseball:populate_ws_champ'].invoke
    Rake::Task['baseball:populate_only_one_team'].invoke
    Rake::Task['baseball:populate_no_hitters'].invoke
    Rake::Task['baseball:populate_6_war_seasons'].invoke
  end
end

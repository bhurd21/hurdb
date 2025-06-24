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
          death_day: row['deathDay'],
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
end

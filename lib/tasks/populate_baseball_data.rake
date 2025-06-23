require 'csv'
require 'activerecord-import'

namespace :baseball do
  desc "Populate baseball data from CSV files"
  task populate_all: :environment do
    populate_all_star_fulls
    populate_appearances
    populate_awards_players
    populate_people
    populate_battings
    populate_hall_of_fames
    populate_pitchings
    populate_teams
  end

  desc "Populate AllStarFull data from CSV"
  task populate_all_star_fulls: :environment do
    model = AllStarFull
    csv_file = Rails.root.join('db', 'csv', 'AllStarFull.csv')
    
    if model.exists?
      puts "#{model.name} already has data (#{model.count} records). Skipping import."
      return
    end
    
    if File.exist?(csv_file)
      puts "Importing #{model.name} data from CSV..."
      records = []
      
      CSV.foreach(csv_file, headers: true) do |row|
        records << model.new(
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
      
      model.import records
      puts "Imported #{records.size} #{model.name} records successfully!"
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
      return
    end
    
    if File.exist?(csv_file)
      puts "Importing #{model.name} data from CSV..."
      records = []
      
      CSV.foreach(csv_file, headers: true) do |row|
        records << model.new(
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
      
      model.import records
      puts "Imported #{records.size} #{model.name} records successfully!"
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
      return
    end
    
    if File.exist?(csv_file)
      puts "Importing #{model.name} data from CSV..."
      records = []
      
      CSV.foreach(csv_file, headers: true) do |row|
        records << model.new(
          player_id: row['playerID'],
          award_id: row['awardID'],
          year_id: row['yearID']&.to_i,
          lg_id: row['lgID'],
          tie: row['tie'],
          notes: row['notes']
        )
      end
      
      model.import records
      puts "Imported #{records.size} #{model.name} records successfully!"
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
      return
    end
    
    if File.exist?(csv_file)
      puts "Importing #{model.name} data from CSV..."
      records = []
      
      CSV.foreach(csv_file, headers: true) do |row|
        records << model.new(
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
      
      model.import records
      puts "Imported #{records.size} #{model.name} records successfully!"
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
      return
    end
    
    if File.exist?(csv_file)
      puts "Importing #{model.name} data from CSV..."
      records = []
      
      CSV.foreach(csv_file, headers: true) do |row|
        records << model.new(
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
      
      model.import records
      puts "Imported #{records.size} #{model.name} records successfully!"
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
      return
    end
    
    if File.exist?(csv_file)
      puts "Importing #{model.name} data from CSV..."
      records = []
      
      CSV.foreach(csv_file, headers: true) do |row|
        records << model.new(
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
      
      model.import records
      puts "Imported #{records.size} #{model.name} records successfully!"
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
      return
    end
    
    if File.exist?(csv_file)
      puts "Importing #{model.name} data from CSV..."
      records = []
      
      CSV.foreach(csv_file, headers: true) do |row|
        records << model.new(
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
      
      model.import records
      puts "Imported #{records.size} #{model.name} records successfully!"
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
      return
    end
    
    if File.exist?(csv_file)
      puts "Importing #{model.name} data from CSV..."
      records = []
      
      CSV.foreach(csv_file, headers: true) do |row|
        records << model.new(
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
      
      model.import records
      puts "Imported #{records.size} #{model.name} records successfully!"
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
end

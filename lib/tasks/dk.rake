namespace :dk do
  desc "Test DraftKings database connection"
  task test_connection: :environment do
    begin
      result = DkGame.connection.execute("SELECT 1 as test")
      puts "✅ DK PostgreSQL database connection successful!"
      puts "Connection details:"
      puts "  Host: #{ENV['DB_HOST']}"
      puts "  Database: #{ENV['DB_NAME']}"
      puts "  Port: #{ENV['DB_PORT']}"
      
      # Test table existence
      table_name = ENV.fetch('TABLE_NAME', 'dk_games')
      table_exists = DkGame.connection.table_exists?(table_name)
      puts "  Table '#{table_name}' exists: #{table_exists ? '✅' : '❌'}"
      
      if table_exists
        count = DkGame.count
        puts "  Record count: #{count}"
        
        if count > 0
          puts "\nSample record:"
          sample = DkGame.first
          puts "  ID: #{sample.id}"
          puts "  Columns: #{DkGame.column_names.join(', ')}"
        end
      end
      
    rescue => e
      puts "❌ DK PostgreSQL database connection failed!"
      puts "Error: #{e.message}"
      puts "\nPlease check your environment variables:"
      puts "  DB_HOST: #{ENV['DB_HOST'] || 'NOT SET'}"
      puts "  DB_PORT: #{ENV['DB_PORT'] || 'NOT SET'}"
      puts "  DB_NAME: #{ENV['DB_NAME'] || 'NOT SET'}"
      puts "  DB_USER: #{ENV['DB_USER'] || 'NOT SET'}"
      puts "  DB_PASSWORD: #{ENV['DB_PASSWORD'] ? '[SET]' : 'NOT SET'}"
      puts "  TABLE_NAME: #{ENV['TABLE_NAME'] || 'dk_games (default)'}"
    end
  end
  
  desc "Show sample DK games data"
  task sample_data: :environment do
    begin
      games = DkGamesService.fetch_games(limit: 3)
      puts "Sample DK Games data (#{games.count} records):"
      games.each_with_index do |game, index|
        puts "\n#{index + 1}. #{game[:home_team]} vs #{game[:away_team]}"
        puts "   Date: #{game[:date]}"
        puts "   Spread: #{game[:home_team]} #{game[:home_spread]}, #{game[:away_team]} #{game[:away_spread]}"
        puts "   Total: #{game[:total]}"
        puts "   Moneyline: #{game[:home_team]} #{game[:home_moneyline]}, #{game[:away_team]} #{game[:away_moneyline]}"
      end
    rescue => e
      puts "❌ Error fetching sample data: #{e.message}"
    end
  end
end

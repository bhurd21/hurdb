# DraftKings Database Integration

This application now supports reading betting data from a PostgreSQL database containing DraftKings games data.

## Configuration

Set the following environment variables to connect to your PostgreSQL database:

```bash
export DB_HOST=your-postgres-host.com
export DB_PORT=5432  
export DB_NAME=your_dk_database_name
export DB_USER=your_db_username
export DB_PASSWORD=your_db_password
export TABLE_NAME=dk_games  # optional, defaults to 'dk_games'
```

## Database Schema

The `dk_games` table should contain columns that match the betting data structure:
- `home_team` - Home team name
- `away_team` - Away team name  
- `home_spread` - Home team spread
- `away_spread` - Away team spread
- `total` - Over/under total
- `home_spread_odds` - Home spread odds
- `away_spread_odds` - Away spread odds  
- `total_odds` - Total bet odds
- `home_moneyline` - Home team moneyline
- `away_moneyline` - Away team moneyline
- Plus timestamps and other metadata

## Usage

The application will automatically:
1. Connect to the PostgreSQL database using the configured environment variables
2. Read from the `dk_games` table (or table specified by `TABLE_NAME`)
3. Transform the data into the betting format expected by the UI
4. Fallback to mock data if the database is unavailable

## Testing

Test your database connection:
```bash
rails dk:test_connection
```

View sample data:
```bash  
rails dk:sample_data
```

## Architecture

- `DkBaseRecord` - Base ActiveRecord class for DK database connection
- `DkGame` - Model representing games in the DK database
- `DkGamesService` - Service layer for fetching and formatting game data
- Fallback mechanism ensures the app works even if the DK database is unavailable

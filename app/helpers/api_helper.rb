module ApiHelper
  # Helper method to safely parse and ingest the questions query parameter
  def ingest_questions_param
    questions_param = params[:questions] || "[]"
    
    JSON.parse(questions_param)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse questions JSON: #{e.message}"
    []
  end

  # Process each query value in the array
  def process_queries(questions)
    Rails.logger.info "Processing questions: #{questions.inspect}"
    
    questions.map.with_index do |question, index|
      process_query(question, index)
    end
  end

  # Main query processing method with pattern matching
  def process_query(question, index = 0)
    # Try each pattern matcher until one succeeds
    query_patterns.each do |pattern_config|
      result = pattern_config[:matcher].call(question)
      if result[:matched]
        query = pattern_config[:query_builder].call(result[:data])
        suggestions = execute_query(query)
        
        return {
          label: question,
          suggestions: suggestions.first(10),
          pattern_type: pattern_config[:name]
        }
      end
    end

    # No pattern matched
    {
      label: question,
      suggestions: [],
      pattern_type: "unmatched"
    }
  end

  private

  def query_patterns
    [
      {
        name: "team_team",
        matcher: method(:match_team_team),
        query_builder: method(:build_team_team_query)
      },
      {
        name: "team_stat",
        matcher: method(:match_team_stat),
        query_builder: method(:build_team_stat_query)
      }
      # Add more patterns here as needed
    ]
  end

  def match_team_team(question)
    conditions = question.split(/\s\+\s/).map(&:strip)
    return { matched: false } unless conditions.length == 2
    
    team1_condition, team2_condition = conditions
    team1_abbr = team_lookup[team1_condition]
    team2_abbr = team_lookup[team2_condition]
    return { matched: false } unless team1_abbr && team2_abbr

    {
        matched: true,
        data: {
          team1: team1_abbr,
          team2: team2_abbr
        }
    }
  end

  def match_team_stat(question)
    conditions = question.split(/\s\+\s/).map(&:strip)
    return { matched: false } unless conditions.length == 2

    team_condition = conditions.find { |c| team_lookup.key?(c) }
    stat_condition = conditions.find { |c| c.match?(/Season|Career/i) }
    return { matched: false } unless team_condition && stat_condition

    timeframe = stat_condition[/Season|Career/i]&.capitalize
    return { matched: false } unless timeframe

    stat_match = stat_condition.match(/\b(?<value>\<?\.?\d+(?:\.\d+)?)(?<op>\+)?\s(?<stat>[A-Za-z]+)\s(Season|Career)\b/i)
    return { matched: false } unless stat_match
    
    value = stat_match[:value]
    stat_name = stat_match[:stat].strip.upcase
    stat_object = stat_lookup[stat_name]
    return { matched: false } unless stat_object

    team_abbr = team_lookup[team_condition]
    return { matched: false } unless team_abbr

    {
        matched: true,
        data: {
            team_abbr: team_abbr,
            stat_value: value.to_f,
            timeframe: timeframe,
            stat_name: stat_name,
            stat_column: stat_object['column'],
            stat_operator: stat_object['operator'],
            stat_table: stat_object['table']
        }
    }
  end

  def build_team_team_query(data)
    team1 = data[:team1]
    team2 = data[:team2]
    
    """
    WITH target_teams AS (
        SELECT '#{team1}' AS teamID
        UNION ALL 
        SELECT '#{team2}' AS teamID
    ),
    players_both_teams AS (
        SELECT a.playerID
        FROM Appearances a
        JOIN target_teams t ON a.teamID = t.teamID
        WHERE a.yearID > 1899
        GROUP BY a.playerID
        HAVING COUNT(DISTINCT a.teamID) = 2
    )
    SELECT DISTINCT 
        CONCAT(p.nameFirst, ' ', p.nameLast) AS nameFull,
        SUM(a.G_all) AS total_games,
        CASE 
            WHEN p.birthYear IS NOT NULL THEN 2025 - p.birthYear 
            ELSE NULL 
        END AS age
    FROM players_both_teams pbt
    JOIN People p ON p.playerID = pbt.playerID
    JOIN Appearances a ON a.playerID = pbt.playerID
    JOIN target_teams t ON a.teamID = t.teamID
    WHERE a.yearID > 1899
    GROUP BY p.playerID, p.nameFirst, p.nameLast, p.birthYear
    ORDER BY total_games ASC, age DESC;
    """
  end

  def build_team_stat_query(data)
    team_abbr = data[:team_abbr]
    stat_value = data[:stat_value]
    timeframe = data[:timeframe]
    stat_name = data[:stat_name]
    stat_column = data[:stat_column]
    stat_operator = data[:stat_operator] == 'gte' ? '>=' : '<='
    stat_table = data[:stat_table]

    if stat_column.nil?
        stat_column = case stat_name
        when 'AVG'
            'sum(H) / sum(AB)'
        when 'ERA'
            'sum(ER) / sum(IP) * 9'
        else
            raise "Unknown stat name: #{stat_name}"
        end
    else
        stat_column = "sum(#{stat_column})"
    end

    if timeframe == 'Season'
        return """
            with initial_condition as (
                select distinct playerID
                from #{stat_table}
                where teamID = '#{team_abbr}'
                group by playerID, yearID
                having #{stat_column} #{stat_operator} #{stat_value}
            )
            select
                concat(p.nameFirst, ' ', p.nameLast) as nameFull,
                null as total_games,
                case 
                    when p.birthYear is not null then 2025 - p.birthYear 
                    else null 
                end as age
            from initial_condition ic
            left join People p
                on p.playerID = ic.playerID
            order by age desc;
        """
    else
        return """
            with stat_condition as (
                select distinct playerID
                from #{stat_table}
                group by playerID
                having #{stat_column} #{stat_operator} #{stat_value}
            ),
            team_condition as (
                select distinct playerID
                from Appearances
                where teamID = '#{team_abbr}'
            )
            select
                concat(p.nameFirst, ' ', p.nameLast) as nameFull,
                null as total_games,
                case 
                    when p.birthYear is not null then 2025 - p.birthYear 
                    else null 
                end as age
            from stat_condition sc
            left join People p
                on p.playerID = sc.playerID
            where sc.playerID in (select * from team_condition)
            order by age desc;
        """
    end
  end

  # Team abbreviations mapping
  def team_lookup
    {
      "Washington Nationals" =>     "WAS",
      "Toronto Blue Jays" =>        "TOR",
      "Texas Rangers" =>            "TEX",
      "Tampa Bay Rays" =>           "TBA",
      "St. Louis Cardinals" =>      "SLN",
      "San Francisco Giants" =>     "SFN",
      "Seattle Mariners" =>         "SEA",
      "San Diego Padres" =>         "SDN",
      "Pittsburgh Pirates" =>       "PIT",
      "Philadelphia Phillies" =>    "PHI",
      "Athletics" =>                "OAK",
      "New York Yankees" =>         "NYA",
      "New York Mets" =>            "NYN",
      "Minnesota Twins" =>          "MIN",
      "Milwaukee Brewers" =>        "MIL",
      "Los Angeles Dodgers" =>      "LAN",
      "Kansas City Royals" =>       "KCA",
      "Houston Astros" =>           "HOU",
      "Miami Marlins" =>            "MIA",
      "Detroit Tigers" =>           "DET",
      "Colorado Rockies" =>         "COL",
      "Cleveland Guardians" =>      "CLE",
      "Cincinnati Reds" =>          "CIN",
      "Chicago White Sox" =>        "CHA",
      "Chicago Cubs" =>             "CHN",
      "Boston Red Sox" =>           "BOS",
      "Baltimore Orioles" =>        "BAL",
      "Atlanta Braves" =>           "ATL",
      "Arizona Diamondbacks" =>     "ARI",
      "Los Angeles Angels" =>       "LAA",
    }
  end

  def stat_lookup
    {
        'HITS' =>   { 'column' => 'H',      'operator' => 'gte', 'table' => 'Batting'  },
        'HR' =>     { 'column' => 'HR',     'operator' => 'gte', 'table' => 'Batting'  },
        'RBI' =>    { 'column' => 'RBI',    'operator' => 'gte', 'table' => 'Batting'  },
        'AVG' =>    { 'column' => nil,      'operator' => 'gte', 'table' => 'Batting'  },
        'RUN' =>    { 'column' => 'R',      'operator' => 'gte', 'table' => 'Batting'  },
        'SB' =>     { 'column' => 'SB',     'operator' => 'gte', 'table' => 'Batting'  },
        '2B' =>     { 'column' => '2B',     'operator' => 'gte', 'table' => 'Batting'  },
        'WINS' =>   { 'column' => 'W',      'operator' => 'gte', 'table' => 'Pitching' },
        'ERA' =>    { 'column' => nil,      'operator' => 'lte', 'table' => 'Pitching' },
        'K' =>      { 'column' => 'SO',     'operator' => 'gte', 'table' => 'Pitching' },
        'SAVE' =>   { 'column' => 'SV',     'operator' => 'gte', 'table' => 'Pitching' },
    }
  end

  # Execute the built query and return results
  def execute_query(query)
    begin
      # Establish MySQL connection using the configuration
      MysqlConnection.establish_mysql_connection
      
      # Execute the query and fetch results
      results = MysqlConnection.connection.execute(query)
      
      # Convert results to array of hashes with column names as keys
      results.to_a
    rescue => e
      Rails.logger.error "MySQL query execution failed: #{e.message}"
      Rails.logger.error "Query: #{query}"
      []
    ensure
      # Close the connection if it was established
      begin
        MysqlConnection.connection.close if MysqlConnection.connected?
      rescue => e
        Rails.logger.error "Error closing MySQL connection: #{e.message}"
      end
    end
  end
end

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
        suggestions = execute_pattern_query(pattern_config[:name], result[:data])
        
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
        matcher: method(:match_team_team)
      },
      {
        name: "team_stat",
        matcher: method(:match_team_stat)
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

  # Execute queries using raw SQL directly
  def execute_pattern_query(pattern_name, data)
    begin
      case pattern_name
      when "team_team"
        sql = build_team_team_query(data)
        execute_sql(sql)
      when "team_stat"
        sql = build_team_stat_query(data)
        execute_sql(sql)
      else
        []
      end
    rescue => e
      Rails.logger.error "Query execution failed: #{e.message}"
      Rails.logger.error "Pattern: #{pattern_name}, Data: #{data}"
      []
    end
  end

  # Execute raw SQL and return results as array of hashes
  def execute_sql(sql)
    begin
      results = ActiveRecord::Base.connection.execute(sql)
      # Convert to array of hashes with string keys (matching original MySQL format)
      results.map(&:to_h)
    rescue => e
      Rails.logger.error "SQL execution failed: #{e.message}"
      Rails.logger.error "SQL: #{sql}"
      []
    end
  end

  def build_team_team_query(data)
    team1 = data[:team1]
    team2 = data[:team2]
    
    """
    WITH target_teams AS (
        SELECT '#{team1}' AS team_id
        UNION ALL 
        SELECT '#{team2}' AS team_id
    ),
    players_both_teams AS (
        SELECT a.player_id
        FROM appearances a
        JOIN target_teams t ON a.team_id = t.team_id
        WHERE a.year_id > 1899
        GROUP BY a.player_id
        HAVING COUNT(DISTINCT a.team_id) = 2
    )
    SELECT DISTINCT 
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        'XX' as position,  -- Placeholder for position
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        null as lps,  -- Placeholder for lps
        p.bbref_id
    FROM players_both_teams pbt
    JOIN people p ON p.player_id = pbt.player_id
    JOIN appearances a ON a.player_id = pbt.player_id
    JOIN target_teams t ON a.team_id = t.team_id
    WHERE a.year_id > 1899
    GROUP BY p.player_id, p.name_first, p.name_last, p.birth_year
    ORDER BY age DESC;
    """
  end

  def build_team_stat_query(data)
    team_abbr = data[:team_abbr]
    stat_value = data[:stat_value]
    timeframe = data[:timeframe]
    stat_name = data[:stat_name]
    stat_column = data[:stat_column]
    stat_operator = data[:stat_operator]
    stat_table = data[:stat_table]
    
    table_name = stat_table.downcase.pluralize # 'Batting' -> 'battings', 'Pitching' -> 'pitchings'
    operator_sql = stat_operator == 'gte' ? '>=' : '<='
    
    # Handle calculated stats like AVG and ERA
    if stat_column.nil?
      stat_sql = case stat_name
      when 'AVG'
        'CAST(SUM(h) AS FLOAT) / SUM(ab)'
      when 'ERA'
        'CAST(SUM(er) AS FLOAT) / SUM(ip_outs) * 27'
      else
        raise "Unknown stat name: #{stat_name}"
      end
    else
      stat_sql = "SUM(#{stat_column})"
    end

    if timeframe == 'Season'
      """
      WITH initial_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          WHERE team_id = '#{team_abbr}'
          GROUP BY player_id, year_id
          HAVING #{stat_sql} #{operator_sql} #{stat_value}
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        'XX' as position,  -- Placeholder for position
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        null as lps,  -- Placeholder for lps
        p.bbref_id
      FROM initial_condition ic
      LEFT JOIN people p ON p.player_id = ic.player_id
      ORDER BY age DESC;
      """
    else
      """
      WITH stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          GROUP BY player_id
          HAVING #{stat_sql} #{operator_sql} #{stat_value}
      ),
      team_condition AS (
          SELECT DISTINCT player_id
          FROM appearances
          WHERE team_id = '#{team_abbr}'
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        'XX' as position,  -- Placeholder for position
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        null as lps,  -- Placeholder for lps
        p.bbref_id
      FROM stat_condition sc
      LEFT JOIN people p ON p.player_id = sc.player_id
      WHERE sc.player_id IN (SELECT player_id FROM team_condition)
      ORDER BY age DESC;
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
        'HITS' =>   { 'column' => 'h',      'operator' => 'gte', 'table' => 'Batting'  },
        'HR' =>     { 'column' => 'hr',     'operator' => 'gte', 'table' => 'Batting'  },
        'RBI' =>    { 'column' => 'rbi',    'operator' => 'gte', 'table' => 'Batting'  },
        'AVG' =>    { 'column' => nil,      'operator' => 'gte', 'table' => 'Batting'  },
        'RUN' =>    { 'column' => 'r',      'operator' => 'gte', 'table' => 'Batting'  },
        'SB' =>     { 'column' => 'sb',     'operator' => 'gte', 'table' => 'Batting'  },
        '2B' =>     { 'column' => 'doubles', 'operator' => 'gte', 'table' => 'Batting'  },
        'WINS' =>   { 'column' => 'w',      'operator' => 'gte', 'table' => 'Pitching' },
        'ERA' =>    { 'column' => nil,      'operator' => 'lte', 'table' => 'Pitching' },
        'K' =>      { 'column' => 'so',     'operator' => 'gte', 'table' => 'Pitching' },
        'SAVE' =>   { 'column' => 'sv',     'operator' => 'gte', 'table' => 'Pitching' },
    }
  end
end

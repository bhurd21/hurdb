class Questions::PlayedPositionService < Questions::BaseQuestionService
  private

  def match_pattern
    # Match patterns like "Played Catcher min. 1 game", "Pitched min. 1 game", "Caught min. 1 game", etc.
    # Split by '+' to check for team condition
    conditions = @question.split(/\s\+\s/).map(&:strip)
    
    # Find the position condition - could be "Played {Position}" or position-specific verbs
    position_condition = conditions.find { |c| 
      c.match?(/^Played\s+.+\s+min\.\s+1\s+game$/i) || 
      c.match?(/^Pitched\s+min\.\s+1\s+game$/i) ||
      c.match?(/^Caught\s+min\.\s+1\s+game$/i)
    }
    return { matched: false } unless position_condition
    
    # Extract position from different patterns
    position_name = nil
    position_column = nil
    
    if position_condition.match?(/^Played\s+(.+)\s+min\.\s+1\s+game$/i)
      # "Played {Position} min. 1 game"
      position_match = position_condition.match(/^Played\s+(.+)\s+min\.\s+1\s+game$/i)
      position_name = position_match[1].strip
      position_column = position_lookup[position_name] || position_lookup[position_name.split.map(&:capitalize).join(' ')]
    elsif position_condition.match?(/^Pitched\s+min\.\s+1\s+game$/i)
      # "Pitched min. 1 game"
      position_name = 'Pitcher'
      position_column = position_lookup['Pitcher']
    elsif position_condition.match?(/^Caught\s+min\.\s+1\s+game$/i)
      # "Caught min. 1 game"
      position_name = 'Catcher'
      position_column = position_lookup['Catcher']
    end
    
    return { matched: false } unless position_column
    
    # Check for team condition - if there are multiple conditions, ALL non-position conditions must be valid teams
    other_conditions = conditions.reject { |c| c == position_condition }
    
    if other_conditions.any?
      # If there are other conditions, they must all be valid teams
      team_condition = other_conditions.find { |c| team_lookup.key?(c) }
      return { matched: false } unless team_condition && other_conditions.size == 1
      team_abbr = team_lookup[team_condition]
    else
      # No other conditions, just position
      team_abbr = nil
    end
    
    {
      matched: true,
      data: {
        position_name: position_name,
        position_column: position_column,
        team_abbr: team_abbr
      }
    }
  end

  def build_query(data)
    position_column = data[:position_column]
    team_abbr = data[:team_abbr]
    
    if team_abbr
      # Query for played position + team
      build_team_position_query(position_column, team_abbr)
    else
      # Query for played position only (any team)
      build_position_only_query(position_column)
    end
  end

  def build_team_position_query(position_column, team_abbr)
    <<~SQL
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, 2025 - p.birth_year DESC) as lps,
        p.bbref_id
      FROM appearances a
      JOIN people p ON p.player_id = a.player_id
      WHERE a.team_id = '#{team_abbr}'
        AND a.#{position_column} > 0
        AND a.year_id > 1899
      GROUP BY p.player_id, p.name_first, p.name_last, p.birth_year, p.primary_position, p.debut, p.final_game, p.bwar_career, p.bbref_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def build_position_only_query(position_column)
    <<~SQL
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, 2025 - p.birth_year DESC) as lps,
        p.bbref_id
      FROM appearances a
      JOIN people p ON p.player_id = a.player_id
      WHERE a.#{position_column} > 0
        AND a.year_id > 1899
      GROUP BY p.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def position_lookup
    DataLookupHelper.position_lookup
  end
end

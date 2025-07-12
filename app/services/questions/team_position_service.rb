class Questions::TeamPositionService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # Find position condition
    position_condition = conditions.find { |c| 
      c.match?(/^(Played\s+.+\s+min\.\s+1\s+game|Pitched\s+min\.\s+1\s+game|Caught\s+min\.\s+1\s+game|Designated\s+Hitter\s+min\.\s+1\s+game)$/i) 
    }
    return { matched: false } unless position_condition

    # Find team condition
    team_condition = conditions.find { |c| c != position_condition && team_lookup.key?(c) }
    return { matched: false } unless team_condition

    # Extract position info
    position_name, position_column = extract_position_info(position_condition)
    return { matched: false } unless position_column

    team_abbr = team_lookup[team_condition]
    return { matched: false } unless team_abbr

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
    
    <<~SQL
      WITH initial_condition AS (
        SELECT player_id
        FROM appearances
        WHERE team_id = '#{team_abbr}'
        GROUP BY player_id
        HAVING SUM(#{position_column}) > 0
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM initial_condition ic
      LEFT JOIN people p ON p.player_id = ic.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  private
end

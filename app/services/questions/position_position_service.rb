class Questions::PositionPositionService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # Check if both conditions are position conditions
    position_conditions = conditions.select { |c| 
      c.match?(/^(Played\s+.+\s+min\.\s+1\s+game|Pitched\s+min\.\s+1\s+game|Caught\s+min\.\s+1\s+game)$/i) 
    }
    return { matched: false } unless position_conditions.length == 2

    # Extract position info for both conditions
    position1_name, position1_column = extract_position_info(position_conditions[0])
    position2_name, position2_column = extract_position_info(position_conditions[1])
    
    return { matched: false } unless position1_column && position2_column

    {
      matched: true,
      data: {
        position1_name: position1_name,
        position1_column: position1_column,
        position2_name: position2_name,
        position2_column: position2_column
      }
    }
  end

  def build_query(data)
    position1_column = data[:position1_column]
    position2_column = data[:position2_column]
    
    <<~SQL
      WITH initial_condition AS (
        SELECT player_id
        FROM appearances
        GROUP BY player_id
        HAVING SUM(#{position1_column}) > 0 AND SUM(#{position2_column}) > 0
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career ASC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM initial_condition ic
      LEFT JOIN people p ON p.player_id = ic.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  private
end

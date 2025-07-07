class Questions::MultiPositionService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = @question.split(/\s\+\s/).map(&:strip)
    return { matched: false } unless conditions.length == 2

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
      WITH position1_condition AS (
          SELECT DISTINCT player_id, year_id
          FROM appearances
          WHERE #{position1_column} > 0
            AND year_id > 1899
      ),
      position2_condition AS (
          SELECT DISTINCT player_id, year_id
          FROM appearances
          WHERE #{position2_column} > 0
            AND year_id > 1899
      ),
      both_positions AS (
          SELECT p1.player_id
          FROM position1_condition p1
          JOIN position2_condition p2 ON p1.player_id = p2.player_id
          GROUP BY p1.player_id
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, 2025 - p.birth_year DESC) as lps,
        p.bbref_id
      FROM both_positions bp
      JOIN people p ON p.player_id = bp.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def extract_position_info(position_condition)
    # Handle "Pitched min. 1 game"
    if position_condition.match?(/^Pitched\s+min\.\s+1\s+game$/i)
      return ['Pitcher', 'g_p']
    end
    
    # Handle "Caught min. 1 game"  
    if position_condition.match?(/^Caught\s+min\.\s+1\s+game$/i)
      return ['Catcher', 'g_c']
    end
    
    # Handle "Played {Position} min. 1 game"
    position_match = position_condition.match(/^Played\s+(.+)\s+min\.\s+1\s+game$/i)
    if position_match
      position_name = position_match[1].strip
      position_column = position_lookup[position_name] || position_lookup[position_name.split.map(&:capitalize).join(' ')]
      return [position_name, position_column] if position_column
    end
    
    [nil, nil]
  end

  def position_lookup
    DataLookupHelper.position_lookup
  end
end

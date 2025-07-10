class Questions::PositionPlayerService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # One condition should be position, one should be player
    position_conditions = conditions.select { |c| 
      c.match?(/^(Played\s+.+\s+min\.\s+1\s+game|Pitched\s+min\.\s+1\s+game|Caught\s+min\.\s+1\s+game)$/i) 
    }
    player_conditions = conditions.select { |c| player_lookup[c] }
    
    return { matched: false } unless position_conditions.length == 1 && player_conditions.length == 1

    # Extract info for both conditions
    position_name, position_column = extract_position_info(position_conditions[0])
    player_info = extract_player_info(player_conditions[0])
    
    return { matched: false } unless position_column && player_info

    {
      matched: true,
      data: {
        position_name: position_name,
        position_column: position_column,
        player_condition: player_info[:condition],
        player_where: player_info[:where_clause]
      }
    }
  end

  def build_query(data)
    <<~SQL
      WITH position_condition AS (
          SELECT DISTINCT player_id
          FROM appearances
          WHERE #{data[:position_column]} >= 1
      ),
      player_condition AS (
          SELECT DISTINCT player_id
          FROM people
          WHERE #{data[:player_where]}
      ),
      position_player_intersection AS (
          SELECT player_id
          FROM position_condition
          INTERSECT
          SELECT player_id
          FROM player_condition
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        null as lps,
        p.bbref_id
      FROM position_player_intersection ppi
      LEFT JOIN people p ON p.player_id = ppi.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end
end

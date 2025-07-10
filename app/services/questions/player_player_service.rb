class Questions::PlayerPlayerService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # Both conditions should be player conditions
    player_conditions = conditions.select { |c| player_lookup[c] }
    return { matched: false } unless player_conditions.length == 2

    # Extract player info for both conditions
    player1_info = extract_player_info(player_conditions[0])
    player2_info = extract_player_info(player_conditions[1])
    
    return { matched: false } unless player1_info && player2_info

    {
      matched: true,
      data: {
        player1_condition: player1_info[:condition],
        player1_where: player1_info[:where_clause],
        player2_condition: player2_info[:condition],
        player2_where: player2_info[:where_clause]
      }
    }
  end

  def build_query(data)
    <<~SQL
      WITH player_condition1 AS (
          SELECT DISTINCT player_id
          FROM people
          WHERE #{data[:player1_where]}
      ),
      player_condition2 AS (
          SELECT DISTINCT player_id
          FROM people
          WHERE #{data[:player2_where]}
      ),
      player_intersection AS (
          SELECT player_id
          FROM player_condition1
          INTERSECT
          SELECT player_id
          FROM player_condition2
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        null as lps,
        p.bbref_id
      FROM player_intersection pi
      LEFT JOIN people p ON p.player_id = pi.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end
end

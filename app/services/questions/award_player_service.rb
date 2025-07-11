class Questions::AwardPlayerService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # One condition should be award, one should be player
    award_conditions = conditions.select { |c| award_lookup[c] }
    player_conditions = conditions.select { |c| player_lookup[c] }
    
    return { matched: false } unless award_conditions.length == 1 && player_conditions.length == 1

    # Extract info for both conditions
    award_info = extract_award_info(award_conditions[0])
    player_info = extract_player_info(player_conditions[0])
    
    return { matched: false } unless award_info && player_info

    {
      matched: true,
      data: {
        award_condition: award_info[:condition],
        award_id: award_info[:award_id],
        player_condition: player_info[:condition],
        player_where: player_info[:where_clause]
      }
    }
  end

  def build_query(data)
    # Handle special case for All Star
    award_query = if data[:award_id] == 'All Star'
      "award_condition AS (
          SELECT DISTINCT player_id
          FROM all_star_fulls
      )"
    else
      "award_condition AS (
          SELECT DISTINCT player_id
          FROM awards_players
          WHERE award_id = '#{data[:award_id]}'
      )"
    end

    <<~SQL
      WITH #{award_query},
      player_condition AS (
          SELECT DISTINCT player_id
          FROM people
          WHERE #{data[:player_where]}
      ),
      award_player_intersection AS (
          SELECT player_id
          FROM award_condition
          INTERSECT
          SELECT player_id
          FROM player_condition
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM award_player_intersection api
      LEFT JOIN people p ON p.player_id = api.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end
end

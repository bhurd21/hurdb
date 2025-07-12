class Questions::AwardPositionService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # Find award condition
    award_condition = conditions.find { |c| award_lookup[c] }
    return { matched: false } unless award_condition

    # Find position condition
    position_condition = conditions.find { |c| 
      c != award_condition && c.match?(/^(Played\s+.+\s+min\.\s+1\s+game|Pitched\s+min\.\s+1\s+game|Caught\s+min\.\s+1\s+game)$/i) 
    }
    return { matched: false } unless position_condition

    # Extract info for both conditions
    award_info = extract_award_info(award_condition)
    position_name, position_column = extract_position_info(position_condition)
    
    return { matched: false } unless award_info && position_column

    {
      matched: true,
      data: {
        award_condition: award_info[:condition],
        award_id: award_info[:award_id],
        position_name: position_name,
        position_column: position_column
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
      position_condition AS (
          SELECT DISTINCT player_id
          FROM appearances
          WHERE #{data[:position_column]} > 0
      ),
      award_position_intersection AS (
          SELECT player_id
          FROM award_condition
          INTERSECT
          SELECT player_id
          FROM position_condition
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM award_position_intersection api
      LEFT JOIN people p ON p.player_id = api.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end
end

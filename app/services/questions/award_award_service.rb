class Questions::AwardAwardService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # Both conditions should be award conditions
    award_conditions = conditions.select { |c| award_lookup[c] }
    return { matched: false } unless award_conditions.length == 2

    # Extract award info for both conditions
    award1_info = extract_award_info(award_conditions[0])
    award2_info = extract_award_info(award_conditions[1])
    
    return { matched: false } unless award1_info && award2_info

    {
      matched: true,
      data: {
        award1_condition: award1_info[:condition],
        award1_id: award1_info[:award_id],
        award2_condition: award2_info[:condition],
        award2_id: award2_info[:award_id]
      }
    }
  end

  def build_query(data)
    # Handle special cases for All Star
    award1_query = build_award_subquery(data[:award1_id], 'award1')
    award2_query = build_award_subquery(data[:award2_id], 'award2')

    <<~SQL
      WITH #{award1_query},
      #{award2_query},
      award_intersection AS (
          SELECT player_id
          FROM award1_players
          INTERSECT
          SELECT player_id
          FROM award2_players
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM award_intersection ai
      LEFT JOIN people p ON p.player_id = ai.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  private

  def build_award_subquery(award_id, alias_name)
    if award_id == 'All Star'
      "#{alias_name}_players AS (
          SELECT DISTINCT player_id
          FROM all_star_fulls
      )"
    else
      "#{alias_name}_players AS (
          SELECT DISTINCT player_id
          FROM awards_players
          WHERE award_id = '#{award_id}'
      )"
    end
  end
end

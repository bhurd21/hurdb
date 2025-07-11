class Questions::AwardTeamService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # One condition should be award, one should be team
    award_conditions = conditions.select { |c| award_lookup[c] }
    team_conditions = conditions.select { |c| team_lookup[c] }
    
    return { matched: false } unless award_conditions.length == 1 && team_conditions.length == 1

    # Extract info for both conditions
    award_info = extract_award_info(award_conditions[0])
    team_name = team_conditions[0]
    team_abbr = team_lookup[team_name]
    
    return { matched: false } unless award_info && team_abbr

    {
      matched: true,
      data: {
        award_condition: award_info[:condition],
        award_id: award_info[:award_id],
        team_name: team_name,
        team_abbr: team_abbr
      }
    }
  end

  def build_query(data)
    # Handle special case for All Star - includes team_id
    if data[:award_id] == 'All Star'
      <<~SQL
        WITH award_team_condition AS (
            SELECT DISTINCT player_id
            FROM all_star_fulls
            WHERE team_id = '#{data[:team_abbr]}'
        )
        SELECT
          CONCAT(p.name_first, ' ', p.name_last) AS name,
          p.primary_position as position,
          substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
          2025 - p.birth_year AS age,
          ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
          p.bbref_id
        FROM award_team_condition atc
        LEFT JOIN people p ON p.player_id = atc.player_id
        ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
      SQL
    else
      # For other awards, need to join with appearances to get team info
      <<~SQL
        WITH award_condition AS (
            SELECT DISTINCT player_id, year_id
            FROM awards_players
            WHERE award_id = '#{data[:award_id]}'
        ),
        team_condition AS (
            SELECT DISTINCT player_id, year_id
            FROM appearances
            WHERE team_id = '#{data[:team_abbr]}'
        ),
        award_team_intersection AS (
            SELECT ac.player_id
            FROM award_condition ac
            INNER JOIN team_condition tc ON ac.player_id = tc.player_id AND ac.year_id = tc.year_id
        )
        SELECT
          CONCAT(p.name_first, ' ', p.name_last) AS name,
          p.primary_position as position,
          substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
          2025 - p.birth_year AS age,
          ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
          p.bbref_id
        FROM award_team_intersection ati
        LEFT JOIN people p ON p.player_id = ati.player_id
        ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
      SQL
    end
  end
end

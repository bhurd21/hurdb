class Questions::TeamTeamService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions
    
    team1_condition, team2_condition = conditions
    team1_abbr = team_lookup[team1_condition]
    team2_abbr = team_lookup[team2_condition]
    return { matched: false } unless team1_abbr && team2_abbr

    {
      matched: true,
      data: {
        team1: team1_abbr,
        team2: team2_abbr
      }
    }
  end

  def build_query(data)
    team1 = data[:team1]
    team2 = data[:team2]
    
    # Build target teams CTE to handle both single values and arrays
    team1_values = team1.is_a?(Array) ? team1 : [team1]
    team2_values = team2.is_a?(Array) ? team2 : [team2]
    all_teams = (team1_values + team2_values).uniq
    
    target_teams_sql = all_teams.map { |team| "SELECT '#{team}' AS team_id" }.join("\nUNION ALL\n")
    
    <<~SQL
      WITH target_teams AS (
          #{target_teams_sql}
      ),
      players_both_teams AS (
          SELECT a.player_id
          FROM appearances a
          JOIN target_teams t ON a.team_id = t.team_id
          WHERE a.year_id > 1899
          GROUP BY a.player_id
          HAVING COUNT(DISTINCT a.team_id) = 2
      )
      SELECT DISTINCT 
          CONCAT(p.name_first, ' ', p.name_last) AS name,
          p.primary_position as position,
          substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
          2025 - p.birth_year AS age,
          ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
          p.bbref_id
      FROM players_both_teams pbt
      JOIN people p ON p.player_id = pbt.player_id
      JOIN appearances a ON a.player_id = pbt.player_id
      JOIN target_teams t ON a.team_id = t.team_id
      WHERE a.year_id > 1899
      GROUP BY p.player_id, p.name_first, p.name_last, p.birth_year
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end
end

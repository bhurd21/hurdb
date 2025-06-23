class Questions::TeamTeamService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = @question.split(/\s\+\s/).map(&:strip)
    return { matched: false } unless conditions.length == 2
    
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
    
    <<~SQL
      WITH target_teams AS (
          SELECT '#{team1}' AS team_id
          UNION ALL 
          SELECT '#{team2}' AS team_id
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
          'XX' as position,
          substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
          2025 - p.birth_year AS age,
          null as lps,
          p.bbref_id
      FROM players_both_teams pbt
      JOIN people p ON p.player_id = pbt.player_id
      JOIN appearances a ON a.player_id = pbt.player_id
      JOIN target_teams t ON a.team_id = t.team_id
      WHERE a.year_id > 1899
      GROUP BY p.player_id, p.name_first, p.name_last, p.birth_year
      ORDER BY age DESC;
    SQL
  end
end

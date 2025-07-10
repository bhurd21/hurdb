class Questions::TeamPlayerService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # One condition should be team, one should be player
    team_conditions = conditions.select { |c| team_lookup[c] }
    player_conditions = conditions.select { |c| player_lookup[c] }
    
    return { matched: false } unless team_conditions.length == 1 && player_conditions.length == 1

    # Extract info for both conditions
    team_name = team_conditions[0]
    team_abbr = team_lookup[team_name]
    player_info = extract_player_info(player_conditions[0])
    
    return { matched: false } unless team_abbr && player_info

    {
      matched: true,
      data: {
        team_name: team_name,
        team_abbr: team_abbr,
        player_condition: player_info[:condition],
        player_where: player_info[:where_clause]
      }
    }
  end

  def build_query(data)
    <<~SQL
      WITH team_condition AS (
          SELECT DISTINCT player_id
          FROM battings
          WHERE team_id = '#{data[:team_abbr]}'
          UNION
          SELECT DISTINCT player_id
          FROM pitchings
          WHERE team_id = '#{data[:team_abbr]}'
      ),
      player_condition AS (
          SELECT DISTINCT player_id
          FROM people
          WHERE #{data[:player_where]}
      ),
      team_player_intersection AS (
          SELECT player_id
          FROM team_condition
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
      FROM team_player_intersection tpi
      LEFT JOIN people p ON p.player_id = tpi.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end
end

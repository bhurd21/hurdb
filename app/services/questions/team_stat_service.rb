class Questions::TeamStatService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    team_condition = conditions.find { |c| team_lookup.key?(c) }
    stat_condition = conditions.find { |c| c.match?(/Season|Career/i) }
    return { matched: false } unless team_condition && stat_condition

    stat_info = extract_stat_info(stat_condition)
    return { matched: false } unless stat_info

    team_abbr = team_lookup[team_condition]
    return { matched: false } unless team_abbr

    # Build the data hash, preserving compound stat information if present
    data = {
      team_abbr: team_abbr,
      stat_value: stat_info[:value],
      timeframe: stat_info[:timeframe],
      stat_name: stat_info[:name],
      stat_column: stat_info[:column],
      stat_operator: stat_info[:operator],
      stat_table: stat_info[:table]
    }
    
    # Add compound stat data if this is a compound stat
    if stat_info[:compound]
      data[:compound] = stat_info[:compound]
      data[:stat1] = stat_info[:stat1]
      data[:stat2] = stat_info[:stat2]
    end

    {
      matched: true,
      data: data
    }
  end

  def build_query(data)
    # Handle compound stats (like "30+ HR / 30+ SB Season Batting")
    if data[:compound]
      return build_compound_stat_query(data)
    end

    team_abbr = data[:team_abbr]
    stat_value = data[:stat_value]
    timeframe = data[:timeframe]
    stat_name = data[:stat_name]
    stat_column = data[:stat_column]
    stat_operator = data[:stat_operator]
    stat_table = data[:stat_table]
    
    table_name = format_table_name(stat_table)
    operator_sql = format_operator_sql(stat_operator)
    stat_sql = build_stat_sql(stat_name, stat_column)

    if timeframe == 'Season'
      build_season_query(table_name, team_abbr, stat_sql, operator_sql, stat_value)
    else
      build_career_query(table_name, team_abbr, stat_sql, operator_sql, stat_value)
    end
  end

  def build_compound_stat_query(data)
    stat1 = data[:stat1]
    stat2 = data[:stat2]
    timeframe = data[:timeframe]
    table_name = format_table_name(data[:stat_table])
    team_abbr = data[:team_abbr]
    
    # Build GROUP BY clause based on timeframe  
    group_by = build_group_by_clause(timeframe)
    
    <<~SQL
      WITH compound_stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          WHERE team_id = '#{team_abbr}' AND year_id > 1899
          GROUP BY #{group_by}
          HAVING SUM(#{stat1[:column]}) >= #{stat1[:value]}
            AND SUM(#{stat2[:column]}) >= #{stat2[:value]}
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM compound_stat_condition csc
      LEFT JOIN people p ON p.player_id = csc.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def build_season_query(table_name, team_abbr, stat_sql, operator_sql, stat_value)
    <<~SQL
      WITH initial_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          WHERE team_id = '#{team_abbr}'
          GROUP BY player_id, year_id
          HAVING #{stat_sql} #{operator_sql} #{stat_value}
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM initial_condition ic
      LEFT JOIN people p ON p.player_id = ic.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def build_career_query(table_name, team_abbr, stat_sql, operator_sql, stat_value)
    <<~SQL
      WITH stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          GROUP BY player_id
          HAVING #{stat_sql} #{operator_sql} #{stat_value}
      ),
      team_condition AS (
          SELECT DISTINCT player_id
          FROM appearances
          WHERE team_id = '#{team_abbr}'
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_condition sc
      LEFT JOIN people p ON p.player_id = sc.player_id
      WHERE sc.player_id IN (SELECT player_id FROM team_condition)
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end
end

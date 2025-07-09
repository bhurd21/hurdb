class Questions::StatStatService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # Both conditions should be stat conditions
    stat_conditions = conditions.select { |c| c.match?(/Season|Career/i) }
    return { matched: false } unless stat_conditions.length == 2

    # Extract stat info for both conditions
    stat1_info = extract_stat_info(stat_conditions[0])
    stat2_info = extract_stat_info(stat_conditions[1])
    
    return { matched: false } unless stat1_info && stat2_info

    {
      matched: true,
      data: {
        stat1_value: stat1_info[:value],
        stat1_name: stat1_info[:name],
        stat1_column: stat1_info[:column],
        stat1_operator: stat1_info[:operator],
        stat1_table: stat1_info[:table],
        stat1_timeframe: stat1_info[:timeframe],
        stat2_value: stat2_info[:value],
        stat2_name: stat2_info[:name],
        stat2_column: stat2_info[:column],
        stat2_operator: stat2_info[:operator],
        stat2_table: stat2_info[:table],
        stat2_timeframe: stat2_info[:timeframe]
      }
    }
  end

  def build_query(data)
    # Extract data for both stats
    stat1_table = format_table_name(data[:stat1_table])
    stat1_operator_sql = format_operator_sql(data[:stat1_operator])
    stat1_sql = build_stat_sql(data[:stat1_name], data[:stat1_column])
    stat1_timeframe = data[:stat1_timeframe]
    stat1_value = data[:stat1_value]
    
    stat2_table = format_table_name(data[:stat2_table])
    stat2_operator_sql = format_operator_sql(data[:stat2_operator])
    stat2_sql = build_stat_sql(data[:stat2_name], data[:stat2_column])
    stat2_timeframe = data[:stat2_timeframe]
    stat2_value = data[:stat2_value]
    
    # Build GROUP BY clauses based on timeframe
    stat1_group_by = build_group_by_clause(stat1_timeframe)
    stat2_group_by = build_group_by_clause(stat2_timeframe)
    
    <<~SQL
      WITH stat_condition1 AS (
          SELECT DISTINCT player_id
          FROM #{stat1_table}
          GROUP BY #{stat1_group_by}
          HAVING #{stat1_sql} #{stat1_operator_sql} #{stat1_value}
      ),
      stat_condition2 AS (
          SELECT DISTINCT player_id
          FROM #{stat2_table}
          GROUP BY #{stat2_group_by}
          HAVING #{stat2_sql} #{stat2_operator_sql} #{stat2_value}
      ),
      stat_intersection AS (
          SELECT player_id
          FROM stat_condition1
          INTERSECT
          SELECT player_id
          FROM stat_condition2
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career ASC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_intersection si
      LEFT JOIN people p ON p.player_id = si.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  private
end

class Questions::StatStatService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # Both conditions should be stat conditions
    stat_conditions = conditions.select { |c| extract_stat_info(c) }
    return { matched: false } unless stat_conditions.length == 2

    # Extract stat info for both conditions
    stat1_info = extract_stat_info(stat_conditions[0])
    stat2_info = extract_stat_info(stat_conditions[1])
    
    return { matched: false } unless stat1_info && stat2_info

    # Build the data hash, preserving compound stat information if present
    data = {
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
    
    # Add compound stat data if either stat is a compound stat
    if stat1_info[:compound]
      data[:stat1_compound] = stat1_info[:compound]
      data[:stat1_stat1] = stat1_info[:stat1]
      data[:stat1_stat2] = stat1_info[:stat2]
    end
    
    if stat2_info[:compound]
      data[:stat2_compound] = stat2_info[:compound]
      data[:stat2_stat1] = stat2_info[:stat1]
      data[:stat2_stat2] = stat2_info[:stat2]
    end

    {
      matched: true,
      data: data
    }
  end

  def build_query(data)
    # Handle compound stats
    if data[:stat1_compound] || data[:stat2_compound]
      return build_compound_stat_query(data)
    end

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
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_intersection si
      LEFT JOIN people p ON p.player_id = si.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def build_compound_stat_query(data)
    # This is complex because we need to handle different combinations:
    # 1. Both stats are compound
    # 2. Only stat1 is compound
    # 3. Only stat2 is compound
    
    if data[:stat1_compound] && data[:stat2_compound]
      # Both stats are compound - very complex case
      build_double_compound_query(data)
    elsif data[:stat1_compound]
      # Only stat1 is compound
      build_single_compound_query(data, 1)
    elsif data[:stat2_compound]
      # Only stat2 is compound
      build_single_compound_query(data, 2)
    end
  end

  def build_single_compound_query(data, compound_stat_num)
    if compound_stat_num == 1
      # stat1 is compound, stat2 is regular
      compound_stat1 = data[:stat1_stat1]
      compound_stat2 = data[:stat1_stat2]
      compound_timeframe = data[:stat1_timeframe]
      compound_table = format_table_name(data[:stat1_table])
      compound_group_by = build_group_by_clause(compound_timeframe)
      
      regular_table = format_table_name(data[:stat2_table])
      regular_operator_sql = format_operator_sql(data[:stat2_operator])
      regular_sql = build_stat_sql(data[:stat2_name], data[:stat2_column])
      regular_timeframe = data[:stat2_timeframe]
      regular_value = data[:stat2_value]
      regular_group_by = build_group_by_clause(regular_timeframe)
    else
      # stat2 is compound, stat1 is regular
      compound_stat1 = data[:stat2_stat1]
      compound_stat2 = data[:stat2_stat2]
      compound_timeframe = data[:stat2_timeframe]
      compound_table = format_table_name(data[:stat2_table])
      compound_group_by = build_group_by_clause(compound_timeframe)
      
      regular_table = format_table_name(data[:stat1_table])
      regular_operator_sql = format_operator_sql(data[:stat1_operator])
      regular_sql = build_stat_sql(data[:stat1_name], data[:stat1_column])
      regular_timeframe = data[:stat1_timeframe]
      regular_value = data[:stat1_value]
      regular_group_by = build_group_by_clause(regular_timeframe)
    end
    
    <<~SQL
      WITH compound_stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{compound_table}
          WHERE year_id > 1899
          GROUP BY #{compound_group_by}
          HAVING SUM(#{compound_stat1[:column]}) >= #{compound_stat1[:value]}
            AND SUM(#{compound_stat2[:column]}) >= #{compound_stat2[:value]}
      ),
      regular_stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{regular_table}
          GROUP BY #{regular_group_by}
          HAVING #{regular_sql} #{regular_operator_sql} #{regular_value}
      ),
      stat_intersection AS (
          SELECT player_id
          FROM compound_stat_condition
          INTERSECT
          SELECT player_id
          FROM regular_stat_condition
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_intersection si
      LEFT JOIN people p ON p.player_id = si.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def build_double_compound_query(data)
    # Both stats are compound - this is a very complex case
    # We'll need to create separate compound conditions for each
    
    stat1_compound_stat1 = data[:stat1_stat1]
    stat1_compound_stat2 = data[:stat1_stat2]
    stat1_timeframe = data[:stat1_timeframe]
    stat1_table = format_table_name(data[:stat1_table])
    stat1_group_by = build_group_by_clause(stat1_timeframe)
    
    stat2_compound_stat1 = data[:stat2_stat1]
    stat2_compound_stat2 = data[:stat2_stat2]
    stat2_timeframe = data[:stat2_timeframe]
    stat2_table = format_table_name(data[:stat2_table])
    stat2_group_by = build_group_by_clause(stat2_timeframe)
    
    <<~SQL
      WITH compound_stat_condition1 AS (
          SELECT DISTINCT player_id
          FROM #{stat1_table}
          WHERE year_id > 1899
          GROUP BY #{stat1_group_by}
          HAVING SUM(#{stat1_compound_stat1[:column]}) >= #{stat1_compound_stat1[:value]}
            AND SUM(#{stat1_compound_stat2[:column]}) >= #{stat1_compound_stat2[:value]}
      ),
      compound_stat_condition2 AS (
          SELECT DISTINCT player_id
          FROM #{stat2_table}
          WHERE year_id > 1899
          GROUP BY #{stat2_group_by}
          HAVING SUM(#{stat2_compound_stat1[:column]}) >= #{stat2_compound_stat1[:value]}
            AND SUM(#{stat2_compound_stat2[:column]}) >= #{stat2_compound_stat2[:value]}
      ),
      stat_intersection AS (
          SELECT player_id
          FROM compound_stat_condition1
          INTERSECT
          SELECT player_id
          FROM compound_stat_condition2
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_intersection si
      LEFT JOIN people p ON p.player_id = si.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  private
end

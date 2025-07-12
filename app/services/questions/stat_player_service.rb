class Questions::StatPlayerService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # One condition should be stat, one should be player
    stat_conditions = conditions.select { |c| c.match?(/Season|Career/i) }
    player_conditions = conditions.select { |c| player_lookup[c] }
    
    return { matched: false } unless stat_conditions.length == 1 && player_conditions.length == 1

    # Extract info for both conditions
    stat_info = extract_stat_info(stat_conditions[0])
    player_info = extract_player_info(player_conditions[0])
    
    return { matched: false } unless stat_info && player_info

    # Build the data hash, preserving compound stat information if present
    data = {
      stat_value: stat_info[:value],
      stat_name: stat_info[:name],
      stat_column: stat_info[:column],
      stat_operator: stat_info[:operator],
      stat_table: stat_info[:table],
      stat_timeframe: stat_info[:timeframe],
      player_condition: player_info[:condition],
      player_where: player_info[:where_clause]
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

    # Extract stat data
    stat_table = format_table_name(data[:stat_table])
    stat_operator_sql = format_operator_sql(data[:stat_operator])
    stat_sql = build_stat_sql(data[:stat_name], data[:stat_column])
    stat_timeframe = data[:stat_timeframe]
    stat_value = data[:stat_value]
    
    # Build GROUP BY clause based on timeframe
    stat_group_by = build_group_by_clause(stat_timeframe)
    
    <<~SQL
      WITH stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{stat_table}
          GROUP BY #{stat_group_by}
          HAVING #{stat_sql} #{stat_operator_sql} #{stat_value}
      ),
      player_condition AS (
          SELECT DISTINCT player_id
          FROM people
          WHERE #{data[:player_where]}
      ),
      stat_player_intersection AS (
          SELECT player_id
          FROM stat_condition
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
      FROM stat_player_intersection spi
      LEFT JOIN people p ON p.player_id = spi.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def build_compound_stat_query(data)
    stat1 = data[:stat1]
    stat2 = data[:stat2]
    timeframe = data[:stat_timeframe]
    table_name = format_table_name(data[:stat_table])
    
    # Build GROUP BY clause based on timeframe  
    group_by = build_group_by_clause(timeframe)
    
    <<~SQL
      WITH compound_stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          WHERE year_id > 1899
          GROUP BY #{group_by}
          HAVING SUM(#{stat1[:column]}) >= #{stat1[:value]}
            AND SUM(#{stat2[:column]}) >= #{stat2[:value]}
      ),
      player_condition AS (
          SELECT DISTINCT player_id
          FROM people
          WHERE #{data[:player_where]}
      ),
      stat_player_intersection AS (
          SELECT player_id
          FROM compound_stat_condition
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
      FROM stat_player_intersection spi
      LEFT JOIN people p ON p.player_id = spi.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end
end

class Questions::AwardStatService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # One condition should be award, one should be stat
    award_conditions = conditions.select { |c| award_lookup[c] }
    stat_conditions = conditions.select { |c| extract_stat_info(c) }
    
    return { matched: false } unless award_conditions.length == 1 && stat_conditions.length == 1

    # Extract info for both conditions
    award_info = extract_award_info(award_conditions[0])
    stat_info = extract_stat_info(stat_conditions[0])
    
    return { matched: false } unless award_info && stat_info

    # Build the data hash, preserving compound stat information if present
    data = {
      award_condition: award_info[:condition],
      award_id: award_info[:award_id],
      stat_value: stat_info[:value],
      stat_name: stat_info[:name],
      stat_column: stat_info[:column],
      stat_operator: stat_info[:operator],
      stat_table: stat_info[:table],
      stat_timeframe: stat_info[:timeframe]
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

    # Build stat query components
    stat_table = format_table_name(data[:stat_table])
    stat_operator_sql = format_operator_sql(data[:stat_operator])
    stat_sql = build_stat_sql(data[:stat_name], data[:stat_column])
    stat_timeframe = data[:stat_timeframe]
    stat_value = data[:stat_value]
    
    # Build GROUP BY clause based on timeframe
    stat_group_by = build_group_by_clause(stat_timeframe)

    <<~SQL
      WITH #{award_query},
      stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{stat_table}
          GROUP BY #{stat_group_by}
          HAVING #{stat_sql} #{stat_operator_sql} #{stat_value}
      ),
      award_stat_intersection AS (
          SELECT player_id
          FROM award_condition
          INTERSECT
          SELECT player_id
          FROM stat_condition
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM award_stat_intersection asi
      LEFT JOIN people p ON p.player_id = asi.player_id
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
      compound_stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          WHERE year_id > 1899
          GROUP BY #{group_by}
          HAVING SUM(#{stat1[:column]}) >= #{stat1[:value]}
            AND SUM(#{stat2[:column]}) >= #{stat2[:value]}
      ),
      award_stat_intersection AS (
          SELECT player_id
          FROM award_condition
          INTERSECT
          SELECT player_id
          FROM compound_stat_condition
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM award_stat_intersection asi
      LEFT JOIN people p ON p.player_id = asi.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end
end

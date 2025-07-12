class Questions::StatPositionService < Questions::BaseQuestionService
  private

  def match_pattern
    # First try to handle as a single stat condition (for compound stats like "30+ HR / 30+ SB Season Batting")
    if @question.match?(/Season|Career/i) && !@question.include?(' + ')
      stat_info = extract_stat_info(@question)
      if stat_info && stat_info[:compound]
        return {
          matched: true,
          data: {
            stat_value: stat_info[:value],
            stat_name: stat_info[:name],
            stat_column: stat_info[:column],
            stat_operator: stat_info[:operator],
            stat_table: stat_info[:table],
            timeframe: stat_info[:timeframe],
            compound: stat_info[:compound],
            stat1: stat_info[:stat1],
            stat2: stat_info[:stat2],
            position_name: nil,
            position_column: nil
          }
        }
      end
    end

    conditions = split_and_validate_conditions(@question)
    return { matched: false } unless conditions

    # Find stat condition
    stat_condition = conditions.find { |c| extract_stat_info(c) }
    return { matched: false } unless stat_condition

    # Find position condition
    position_condition = conditions.find { |c| 
      c != stat_condition && c.match?(/^(Played\s+.+\s+min\.\s+1\s+game|Pitched\s+min\.\s+1\s+game|Caught\s+min\.\s+1\s+game|Designated\s+Hitter\s+min\.\s+1\s+game)$/i) 
    }
    return { matched: false } unless position_condition

    # Extract stat info
    stat_info = extract_stat_info(stat_condition)
    return { matched: false } unless stat_info

    # Extract position info
    position_name, position_column = extract_position_info(position_condition)
    return { matched: false } unless position_column

    # Build the data hash, preserving compound stat information if present
    data = {
      stat_value: stat_info[:value],
      stat_name: stat_info[:name],
      stat_column: stat_info[:column],
      stat_operator: stat_info[:operator],
      stat_table: stat_info[:table],
      timeframe: stat_info[:timeframe],
      position_name: position_name,
      position_column: position_column
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
    timeframe = data[:timeframe]
    stat_value = data[:stat_value]
    
    # Extract position data
    position_column = data[:position_column]
    
    # Build GROUP BY clause based on timeframe
    stat_group_by = build_group_by_clause(timeframe)
    
    <<~SQL
      WITH stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{stat_table}
          GROUP BY #{stat_group_by}
          HAVING #{stat_sql} #{stat_operator_sql} #{stat_value}
      ),
      position_condition AS (
          SELECT player_id
          FROM appearances
          GROUP BY player_id
          HAVING SUM(#{position_column}) > 0
      ),
      stat_position_intersection AS (
          SELECT player_id
          FROM stat_condition
          INTERSECT
          SELECT player_id
          FROM position_condition
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_position_intersection spi
      LEFT JOIN people p ON p.player_id = spi.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def build_compound_stat_query(data)
    stat1 = data[:stat1]
    stat2 = data[:stat2]
    timeframe = data[:timeframe]
    table_name = format_table_name(data[:stat_table])
    
    # Build GROUP BY clause based on timeframe  
    group_by = build_group_by_clause(timeframe)
    
    # Extract position data
    position_column = data[:position_column]
    
    <<~SQL
      WITH compound_stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          WHERE year_id > 1899
          GROUP BY #{group_by}
          HAVING SUM(#{stat1[:column]}) >= #{stat1[:value]}
            AND SUM(#{stat2[:column]}) >= #{stat2[:value]}
      ),
      position_condition AS (
          SELECT player_id
          FROM appearances
          GROUP BY player_id
          HAVING SUM(#{position_column}) > 0
      ),
      stat_position_intersection AS (
          SELECT player_id
          FROM compound_stat_condition
          INTERSECT
          SELECT player_id
          FROM position_condition
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_position_intersection spi
      LEFT JOIN people p ON p.player_id = spi.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  private
end

class Questions::PositionStatService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = @question.split(/\s\+\s/).map(&:strip)
    return { matched: false } unless conditions.length == 2

    # Find position condition
    position_condition = conditions.find { |c| 
      c.match?(/^(Played\s+.+\s+min\.\s+1\s+game|Pitched\s+min\.\s+1\s+game|Caught\s+min\.\s+1\s+game)$/i) 
    }
    return { matched: false } unless position_condition

    # Find stat condition
    stat_condition = conditions.find { |c| 
      c != position_condition && c.match?(/Season|Career/i) 
    }
    return { matched: false } unless stat_condition

    # Extract position info
    position_name, position_column = extract_position_info(position_condition)
    return { matched: false } unless position_column

    # Extract stat info
    stat_info = extract_stat_info(stat_condition)
    return { matched: false } unless stat_info

    {
      matched: true,
      data: {
        position_name: position_name,
        position_column: position_column,
        stat_value: stat_info[:value],
        stat_name: stat_info[:name],
        stat_column: stat_info[:column],
        stat_operator: stat_info[:operator],
        stat_table: stat_info[:table],
        timeframe: stat_info[:timeframe]
      }
    }
  end

  def build_query(data)
    position_column = data[:position_column]
    stat_value = data[:stat_value]
    stat_name = data[:stat_name]
    stat_column = data[:stat_column]
    stat_operator = data[:stat_operator]
    stat_table = data[:stat_table]
    timeframe = data[:timeframe]
    
    table_name = stat_table.downcase.pluralize
    operator_sql = stat_operator == 'gte' ? '>=' : '<='
    stat_sql = build_stat_sql(stat_name, stat_column)

    if timeframe == 'Season'
      build_season_query(table_name, position_column, stat_sql, operator_sql, stat_value)
    else
      build_career_query(table_name, position_column, stat_sql, operator_sql, stat_value)
    end
  end

  def extract_position_info(position_condition)
    # Handle "Pitched min. 1 game"
    if position_condition.match?(/^Pitched\s+min\.\s+1\s+game$/i)
      return ['Pitcher', 'g_p']
    end
    
    # Handle "Caught min. 1 game"  
    if position_condition.match?(/^Caught\s+min\.\s+1\s+game$/i)
      return ['Catcher', 'g_c']
    end
    
    # Handle "Played {Position} min. 1 game"
    position_match = position_condition.match(/^Played\s+(.+)\s+min\.\s+1\s+game$/i)
    if position_match
      position_name = position_match[1].strip
      position_column = position_lookup[position_name] || position_lookup[position_name.split.map(&:capitalize).join(' ')]
      return [position_name, position_column] if position_column
    end
    
    [nil, nil]
  end

  def extract_stat_info(stat_condition)
    timeframe = stat_condition[/Season|Career/i]&.capitalize
    return nil unless timeframe

    stat_match = stat_condition.match(/\b(?<value>\<?\.?\d+(?:\.\d+)?)(?<op>\+)?\s(?<stat>[A-Za-z]+)\s(Season|Career)\b/i)
    return nil unless stat_match
    
    value = stat_match[:value]
    # Handle decimal values like .300
    if stat_condition.start_with?('.')
      value_divisor = 10 ** value.length
      value_numerator = value.to_f
      value = value_numerator / value_divisor
    end
    
    stat_name = stat_match[:stat].strip.upcase
    stat_object = stat_lookup[stat_name]
    return nil unless stat_object

    {
      value: value.to_f,
      name: stat_name,
      column: stat_object['column'],
      operator: stat_object['operator'],
      table: stat_object['table'],
      timeframe: timeframe
    }
  end

  def build_stat_sql(stat_name, stat_column)
    case stat_name
    when 'AVG'
      'CAST(h AS REAL) / CAST(ab AS REAL)'
    when 'ERA'
      'CAST(er AS REAL) * 9 / CAST(ipouts AS REAL) * 3'
    else
      stat_column
    end
  end

  def build_season_query(table_name, position_column, stat_sql, operator_sql, stat_value)
    <<~SQL
      WITH stat_condition AS (
          SELECT DISTINCT s.player_id, s.year_id
          FROM #{table_name} s
          WHERE s.year_id > 1899
          GROUP BY s.player_id, s.year_id
          HAVING #{stat_sql} #{operator_sql} #{stat_value}
      ),
      position_condition AS (
          SELECT DISTINCT player_id, year_id
          FROM appearances
          WHERE #{position_column} > 0
            AND year_id > 1899
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career ASC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_condition sc
      JOIN position_condition pc ON sc.player_id = pc.player_id AND sc.year_id = pc.year_id
      JOIN people p ON p.player_id = sc.player_id
      GROUP BY p.player_id, p.name_first, p.name_last, p.birth_year, p.primary_position, p.debut, p.final_game, p.bwar_career, p.bbref_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def build_career_query(table_name, position_column, stat_sql, operator_sql, stat_value)
    # For career queries, we need to sum up stats
    career_stat_sql = case stat_sql
    when /CAST.*AS REAL/
      stat_sql  # AVG and ERA formulas stay the same
    else
      "SUM(#{stat_sql})"
    end
    
    <<~SQL
      WITH stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          WHERE year_id > 1899
          GROUP BY player_id
          HAVING #{career_stat_sql} #{operator_sql} #{stat_value}
      ),
      position_condition AS (
          SELECT DISTINCT player_id
          FROM appearances
          WHERE #{position_column} > 0
            AND year_id > 1899
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        p.primary_position as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career ASC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_condition sc
      JOIN position_condition pc ON sc.player_id = pc.player_id
      JOIN people p ON p.player_id = sc.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def position_lookup
    DataLookupHelper.position_lookup
  end
end

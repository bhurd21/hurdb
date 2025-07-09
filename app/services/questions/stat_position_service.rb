class Questions::StatPositionService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = @question.split(/\s\+\s/).map(&:strip)
    return { matched: false } unless conditions.length == 2

    # Find stat condition
    stat_condition = conditions.find { |c| c.match?(/Season|Career/i) }
    return { matched: false } unless stat_condition

    # Find position condition
    position_condition = conditions.find { |c| 
      c != stat_condition && c.match?(/^(Played\s+.+\s+min\.\s+1\s+game|Pitched\s+min\.\s+1\s+game|Caught\s+min\.\s+1\s+game)$/i) 
    }
    return { matched: false } unless position_condition

    # Extract stat info
    stat_info = extract_stat_info(stat_condition)
    return { matched: false } unless stat_info

    # Extract position info
    position_name, position_column = extract_position_info(position_condition)
    return { matched: false } unless position_column

    {
      matched: true,
      data: {
        stat_value: stat_info[:value],
        stat_name: stat_info[:name],
        stat_column: stat_info[:column],
        stat_operator: stat_info[:operator],
        stat_table: stat_info[:table],
        timeframe: stat_info[:timeframe],
        position_name: position_name,
        position_column: position_column
      }
    }
  end

  def build_query(data)
    # Extract stat data
    stat_table = data[:stat_table].downcase.pluralize
    stat_operator_sql = data[:stat_operator] == 'gte' ? '>=' : '<='
    stat_sql = build_stat_sql(data[:stat_name], data[:stat_column])
    timeframe = data[:timeframe]
    stat_value = data[:stat_value]
    
    # Extract position data
    position_column = data[:position_column]
    
    # Build GROUP BY clause based on timeframe
    stat_group_by = timeframe == 'Season' ? 'player_id, year_id' : 'player_id'
    
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
        ROW_NUMBER() OVER (ORDER BY p.bwar_career IS NULL DESC, p.bwar_career ASC, p.birth_year DESC) as lps,
        p.bbref_id
      FROM stat_position_intersection spi
      LEFT JOIN people p ON p.player_id = spi.player_id
      ORDER BY p.bwar_career IS NULL DESC, p.bwar_career DESC, age DESC;
    SQL
  end

  def build_stat_sql(stat_name, stat_column)
    return "SUM(#{stat_column})" if stat_column

    case stat_name
    when 'AVG'
      'CAST(SUM(h) AS FLOAT) / SUM(ab)'
    when 'ERA'
      'CAST(SUM(er) AS FLOAT) / SUM(ip_outs) * 27'
    else
      raise "Unknown stat name: #{stat_name}"
    end
  end

  private

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
end

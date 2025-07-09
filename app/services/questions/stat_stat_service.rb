class Questions::StatStatService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = @question.split(/\s\+\s/).map(&:strip)
    return { matched: false } unless conditions.length == 2

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
    stat1_table = data[:stat1_table].downcase.pluralize
    stat1_operator_sql = data[:stat1_operator] == 'gte' ? '>=' : '<='
    stat1_sql = build_stat_sql(data[:stat1_name], data[:stat1_column])
    stat1_timeframe = data[:stat1_timeframe]
    stat1_value = data[:stat1_value]
    
    stat2_table = data[:stat2_table].downcase.pluralize
    stat2_operator_sql = data[:stat2_operator] == 'gte' ? '>=' : '<='
    stat2_sql = build_stat_sql(data[:stat2_name], data[:stat2_column])
    stat2_timeframe = data[:stat2_timeframe]
    stat2_value = data[:stat2_value]
    
    # Build GROUP BY clauses based on timeframe
    stat1_group_by = stat1_timeframe == 'Season' ? 'player_id, year_id' : 'player_id'
    stat2_group_by = stat2_timeframe == 'Season' ? 'player_id, year_id' : 'player_id'
    
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
end

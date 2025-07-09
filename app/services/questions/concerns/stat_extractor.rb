module Questions::Concerns::StatExtractor
  extend ActiveSupport::Concern

  private

  def extract_stat_info(stat_condition)
    timeframe = stat_condition[/Season|Career/i]&.capitalize
    return nil unless timeframe

    stat_match = stat_condition.match(/\b(?<value>\<?\.?\d+(?:\.\d+)?)(?<op>\+)?\s(?<stat>[A-Za-z]+)\s(Season|Career)\b/i)
    return nil unless stat_match
    
    value = parse_decimal_value(stat_match[:value], stat_condition)
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

  def parse_decimal_value(value, stat_condition)
    # Handle decimal values like .300
    if stat_condition.start_with?('.')
      value_divisor = 10 ** value.length
      value_numerator = value.to_f
      value_numerator / value_divisor
    else
      value
    end
  end

  def build_group_by_clause(timeframe)
    timeframe == 'Season' ? 'player_id, year_id' : 'player_id'
  end
end

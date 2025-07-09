module Questions::Concerns::StatExtractor
  extend ActiveSupport::Concern

  private

  def extract_stat_info(stat_condition)
    # Check for compound stat patterns like "30+ HR / 30+ SB Season Batting"
    compound_match = stat_condition.match(/(\d+)\+\s([A-Za-z]+)\s\/\s(\d+)\+\s([A-Za-z]+)\s(Season|Career)\s?(Batting|Pitching)?/i)
    if compound_match
      return extract_compound_stat_info(compound_match)
    end

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

  def extract_compound_stat_info(compound_match)
    value1, stat1, value2, stat2, timeframe = compound_match.captures
    
    stat1_name = stat1.strip.upcase
    stat2_name = stat2.strip.upcase
    
    stat1_object = stat_lookup[stat1_name]
    stat2_object = stat_lookup[stat2_name]
    
    return nil unless stat1_object && stat2_object
    
    # For compound stats, we return a special structure
    {
      value: nil, # Not used for compound stats
      name: "COMPOUND_#{stat1_name}_#{stat2_name}",
      column: nil, # Special handling in build_stat_sql
      operator: 'gte',
      table: stat1_object['table'], # Assume both stats are from same table
      timeframe: timeframe.capitalize,
      compound: true,
      stat1: { name: stat1_name, value: value1.to_f, column: stat1_object['column'] },
      stat2: { name: stat2_name, value: value2.to_f, column: stat2_object['column'] }
    }
  end

  def build_stat_sql(stat_name, stat_column)
    # Handle compound stats
    if stat_name&.start_with?('COMPOUND_')
      return 'compound_stat_placeholder' # This will be replaced in the calling service
    end
    
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

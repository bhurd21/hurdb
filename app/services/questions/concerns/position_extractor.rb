module Questions::Concerns::PositionExtractor
  extend ActiveSupport::Concern

  private

  def extract_position_info(position_condition)
    # Handle "Pitched min. 1 game"
    if position_condition.match?(/^Pitched\s+min\.\s+1\s+game$/i)
      return ['Pitcher', 'g_p']
    end
    
    # Handle "Caught min. 1 game"  
    if position_condition.match?(/^Caught\s+min\.\s+1\s+game$/i)
      return ['Catcher', 'g_c']
    end
    
    # Handle "Designated Hitter min. 1 game"
    if position_condition.match?(/^Designated\s+Hitter\s+min\.\s+1\s+game$/i)
      return ['Designated Hitter', 'g_dh']
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

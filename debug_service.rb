#!/usr/bin/env ruby

# Add the app directory to the load path
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'app'))

# Load Rails environment
require_relative 'config/environment'

# Configuration - Edit this section to test different questions
QUESTION_TO_DEBUG = "First Round Draft Pick + All Star"

# You can also test these other combinations:
# QUESTION_TO_DEBUG = "MVP + Gold Glove"                    # Award + Award
# QUESTION_TO_DEBUG = "All Star + New York Yankees"         # Award + Team  
# QUESTION_TO_DEBUG = "Cy Young + Pitcher"                  # Award + Position
# QUESTION_TO_DEBUG = "All Star + Hall of Fame"             # Award + Player
# QUESTION_TO_DEBUG = "Cincinnati Reds + Chicago Cubs"      # Team + Team
# QUESTION_TO_DEBUG = "New York Yankees + 300+ HR Career"   # Team + Stat
# QUESTION_TO_DEBUG = "Boston Red Sox + Catcher"            # Team + Position
# QUESTION_TO_DEBUG = "300+ HR Career + 3000+ H Career"     # Stat + Stat
# QUESTION_TO_DEBUG = "300+ HR Career + Pitcher"            # Stat + Position
# QUESTION_TO_DEBUG = "Played 1B min. 1 game + Hall of Fame" # Position + Player

puts "=" * 80
puts "SERVICE DEBUGGING TOOL"
puts "=" * 80
puts "Question: \"#{QUESTION_TO_DEBUG}\""
puts "=" * 80

# Step 1: Basic question validation
puts "\n=== Step 1: Question Validation ==="
conditions = QUESTION_TO_DEBUG.split(/\s\+\s/).map(&:strip)
puts "Split conditions: #{conditions.inspect}"
puts "Number of conditions: #{conditions.length}"

if conditions.length != 2
  puts "❌ ERROR: Questions must have exactly 2 conditions separated by ' + '"
  puts "   Example: 'MVP + Gold Glove' or 'New York Yankees + 300+ HR Career'"
  exit 1
end

# Step 2: Analyze each condition type
puts "\n=== Step 2: Condition Analysis ==="
conditions.each_with_index do |condition, index|
  puts "\nCondition #{index + 1}: \"#{condition}\""
  
  # Check condition type
  condition_types = []
  
  # Check for award
  if DataLookupHelper.award_lookup[condition]
    condition_types << "Award"
    puts "  ✅ Award: #{DataLookupHelper.award_lookup[condition]}"
  end
  
  # Check for team
  if DataLookupHelper.team_lookup[condition]
    condition_types << "Team"
    puts "  ✅ Team: #{DataLookupHelper.team_lookup[condition]}"
  end
  
  # Check for player
  if DataLookupHelper.player_lookup[condition]
    condition_types << "Player"
    puts "  ✅ Player: #{DataLookupHelper.player_lookup[condition]}"
  end
  
  # Check for position
  if condition.match?(/^(Played\s+.+\s+min\.\s+1\s+game|Pitched\s+min\.\s+1\s+game|Caught\s+min\.\s+1\s+game|Designated\s+Hitter\s+min\.\s+1\s+game)$/i)
    condition_types << "Position"
    puts "  ✅ Position: #{condition}"
  end
  
  # Check for stat
  if condition.match?(/Season|Career/i)
    condition_types << "Stat"
    puts "  ✅ Stat: #{condition}"
    
    # Show stat parsing details
    stat_match = condition.match(/\b(?<value>\<?\.?\d+(?:\.\d+)?)(?<op>\+)?\s(?<stat>[A-Za-z]+)\s(Season|Career)\b/i)
    if stat_match
      stat_name = stat_match[:stat].strip.upcase
      stat_object = DataLookupHelper.stat_lookup[stat_name]
      puts "    - Value: #{stat_match[:value]}"
      puts "    - Operator: #{stat_match[:op] || 'none'}"
      puts "    - Stat: #{stat_name}"
      puts "    - Timeframe: #{condition[/Season|Career/i]}"
      puts "    - Valid stat: #{!!stat_object}"
    end
  end
  
  if condition_types.empty?
    puts "  ❌ Unknown condition type"
  else
    puts "  📋 Condition types: #{condition_types.join(', ')}"
  end
end

# Step 3: Determine expected service
puts "\n=== Step 3: Expected Service Analysis ==="
condition_types = []
conditions.each do |condition|
  if DataLookupHelper.award_lookup[condition]
    condition_types << "Award"
  elsif DataLookupHelper.team_lookup[condition]
    condition_types << "Team"
  elsif DataLookupHelper.player_lookup[condition]
    condition_types << "Player"
  elsif condition.match?(/^(Played\s+.+\s+min\.\s+1\s+game|Pitched\s+min\.\s+1\s+game|Caught\s+min\.\s+1\s+game|Designated\s+Hitter\s+min\.\s+1\s+game)$/i)
    condition_types << "Position"
  elsif condition.match?(/Season|Career/i)
    condition_types << "Stat"
  else
    condition_types << "Unknown"
  end
end

expected_service = condition_types.sort.join("")
puts "Condition types: #{condition_types.inspect}"
puts "Expected service pattern: #{expected_service}"

# Map to actual service class
service_mapping = {
  "AwardAward" => Questions::AwardAwardService,
  "AwardTeam" => Questions::AwardTeamService,
  "AwardStat" => Questions::AwardStatService,
  "AwardPosition" => Questions::AwardPositionService,
  "AwardPlayer" => Questions::AwardPlayerService,
  "TeamTeam" => Questions::TeamTeamService,
  "StatTeam" => Questions::TeamStatService,
  "PositionTeam" => Questions::TeamPositionService,
  "PlayerTeam" => Questions::TeamPlayerService,
  "StatStat" => Questions::StatStatService,
  "PositionStat" => Questions::StatPositionService,
  "PlayerStat" => Questions::StatPlayerService,
  "PositionPosition" => Questions::PositionPositionService,
  "PlayerPosition" => Questions::PositionPlayerService,
  "PlayerPlayer" => Questions::PlayerPlayerService
}

expected_service_class = service_mapping[expected_service]
puts "Expected service class: #{expected_service_class&.name || 'Unknown'}"

# Step 4: Test each service individually
puts "\n=== Step 4: Service Testing ==="
services_to_test = Questions::ProcessorService::QUESTION_SERVICES

services_to_test.each do |service_class|
  puts "\nTesting #{service_class.name}:"
  
  begin
    service = service_class.new(QUESTION_TO_DEBUG)
    match_result = service.send(:match_pattern)
    
    if match_result[:matched]
      puts "  ✅ MATCH - Pattern matched successfully"
      puts "  📋 Match data keys: #{match_result[:data]&.keys&.inspect || 'none'}"
      
      # Try to build query
      begin
        query = service.send(:build_query, match_result[:data])
        puts "  ✅ QUERY - Query built successfully (#{query.length} chars)"
        
        # Try to execute query
        begin
          result = service.call
          suggestions_count = result[:suggestions]&.length || 0
          puts "  ✅ EXECUTE - Query executed successfully (#{suggestions_count} suggestions)"
          
          if suggestions_count > 0
            puts "  🎯 This is the matching service!"
            puts "  📋 Pattern type: #{result[:pattern_type]}"
          end
        rescue => e
          puts "  ❌ EXECUTE - Query execution failed: #{e.message}"
        end
      rescue => e
        puts "  ❌ QUERY - Query building failed: #{e.message}"
      end
    else
      puts "  ❌ NO MATCH - Pattern did not match"
    end
  rescue => e
    puts "  ❌ ERROR - Service failed: #{e.message}"
  end
end

# Step 5: Final processor test
puts "\n=== Step 5: Processor Integration Test ==="
begin
  processor_result = Questions::ProcessorService.call([QUESTION_TO_DEBUG])
  
  if processor_result && processor_result.first
    result = processor_result.first
    pattern_type = result[:pattern_type]
    suggestions_count = result[:suggestions]&.length || 0
    
    puts "Final processor result:"
    puts "  Pattern type: #{pattern_type}"
    puts "  Suggestions count: #{suggestions_count}"
    
    if pattern_type == "unmatched"
      puts "  ❌ FAILED - Question was not matched by any service"
    elsif suggestions_count == 0
      puts "  ⚠️  PARTIAL - Pattern matched but no suggestions returned"
    else
      puts "  ✅ SUCCESS - Question processed successfully"
      
      # Show a few sample suggestions
      puts "\n  Sample suggestions:"
      result[:suggestions].first(3).each do |suggestion|
        puts "    - #{suggestion['name']} (#{suggestion['position'] || 'N/A'}) #{suggestion['pro_career']}"
      end
    end
  else
    puts "❌ FAILED - Processor returned no results"
  end
rescue => e
  puts "❌ ERROR - Processor failed: #{e.message}"
  puts "  Backtrace: #{e.backtrace.first(3).join(', ')}"
end

puts "\n" + "=" * 80
puts "DEBUGGING COMPLETE"
puts "=" * 80

# Summary
puts "\nSUMMARY:"
puts "- Question: \"#{QUESTION_TO_DEBUG}\""
puts "- Expected service: #{expected_service_class&.name || 'Unknown'}"
puts "- Actual result: #{processor_result&.first&.[](:pattern_type) || 'Failed'}"

if processor_result&.first&.[](:pattern_type) == "unmatched"
  puts "\n🔍 TROUBLESHOOTING TIPS:"
  puts "- Check if all lookup tables contain the required entries"
  puts "- Verify condition parsing logic in the expected service"
  puts "- Ensure service is registered in ProcessorService::QUESTION_SERVICES"
  puts "- Check for typos in condition names"
end

#!/usr/bin/env ruby

# Add the app directory to the load path
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'app'))

# Load Rails environment
require_relative 'config/environment'

# Comprehensive test cases covering all service combinations
TEST_CASES = [
  {
    service_class: Questions::AwardAwardService,
    question: "MVP + Gold Glove",
    description: "Award + Award",
    expected_pattern: "award_award"
  },
  {
    service_class: Questions::AwardTeamService,
    question: "All Star + New York Yankees",
    description: "Award + Team",
    expected_pattern: "award_team"
  },
  {
    service_class: Questions::AwardStatService,
    question: "Silver Slugger + 300+ HR Career Batting",
    description: "Award + Stat",
    expected_pattern: "award_stat"
  },
  {
    service_class: Questions::AwardPositionService,
    question: "Cy Young + Pitcher",
    description: "Award + Position",
    expected_pattern: "award_position"
  },
  {
    service_class: Questions::AwardPlayerService,
    question: "All Star + Hall of Fame",
    description: "Award + Player",
    expected_pattern: "award_player"
  },
  {
    service_class: Questions::TeamTeamService,
    question: "Cincinnati Reds + Chicago Cubs",
    description: "Team + Team",
    expected_pattern: "team_team"
  },
  {
    service_class: Questions::TeamStatService,
    question: "New York Yankees + 300+ HR Career Batting",
    description: "Team + Stat",
    expected_pattern: "team_stat"
  },
  {
    service_class: Questions::TeamPositionService,
    question: "Boston Red Sox + Played 1B min. 1 game",
    description: "Team + Position",
    expected_pattern: "team_position"
  },
  {
    service_class: Questions::TeamPlayerService,
    question: "New York Yankees + Hall of Fame",
    description: "Team + Player",
    expected_pattern: "team_player"
  },
  {
    service_class: Questions::StatStatService,
    question: "300+ HR Career Batting + 3000+ H Career Batting",
    description: "Stat + Stat",
    expected_pattern: "stat_stat"
  },
  {
    service_class: Questions::StatPositionService,
    question: "300+ HR Career Batting + Played 1B min. 1 game",
    description: "Stat + Position",
    expected_pattern: "stat_position"
  },
  {
    service_class: Questions::StatPlayerService,
    question: "300+ HR Career Batting + Hall of Fame",
    description: "Stat + Player",
    expected_pattern: "stat_player"
  },
  {
    service_class: Questions::PositionPositionService,
    question: "Played 1B min. 1 game + Played OF min. 1 game",
    description: "Position + Position",
    expected_pattern: "position_position"
  },
  {
    service_class: Questions::PositionPlayerService,
    question: "Played 1B min. 1 game + Hall of Fame",
    description: "Position + Player",
    expected_pattern: "position_player"
  },
  {
    service_class: Questions::PlayerPlayerService,
    question: "Hall of Fame + Born in California",
    description: "Player + Player",
    expected_pattern: "player_player"
  }
]

puts "=" * 80
puts "COMPREHENSIVE SERVICE COMBINATION TESTS"
puts "=" * 80

successful_tests = 0
failed_tests = 0
results = []

TEST_CASES.each_with_index do |test_case, index|
  puts "\n#{index + 1}. Testing #{test_case[:service_class].name}"
  puts "   Description: #{test_case[:description]}"
  puts "   Question: \"#{test_case[:question]}\""
  puts "   Expected pattern: #{test_case[:expected_pattern]}"
  puts "   " + "-" * 70
  
  begin
    # Process the question through the full pipeline
    processor_result = Questions::ProcessorService.call([test_case[:question]])
    
    if processor_result.empty?
      puts "   ❌ ERROR: No results returned from processor"
      failed_tests += 1
      results << {
        service: test_case[:service_class].name,
        question: test_case[:question],
        status: "FAILED",
        reason: "No processor results",
        pattern_type: "none",
        suggestions_count: 0
      }
      next
    end
    
    question_result = processor_result.first
    pattern_type = question_result[:pattern_type]
    suggestions_count = question_result[:suggestions]&.length || 0
    
    # Check if pattern matches expected
    pattern_match = pattern_type == test_case[:expected_pattern]
    has_suggestions = suggestions_count > 0
    
    if pattern_match && has_suggestions
      puts "   ✅ PASSED - Pattern: #{pattern_type}, Suggestions: #{suggestions_count}"
      successful_tests += 1
      results << {
        service: test_case[:service_class].name,
        question: test_case[:question],
        status: "PASSED",
        reason: "Pattern matched and suggestions returned",
        pattern_type: pattern_type,
        suggestions_count: suggestions_count
      }
      
      # Show first few suggestions
      if suggestions_count > 0
        puts "   Sample suggestions:"
        question_result[:suggestions].first(2).each do |suggestion|
          puts "     - #{suggestion['name']} (#{suggestion['position'] || 'N/A'}) #{suggestion['pro_career']}"
        end
      end
    else
      failure_reason = []
      failure_reason << "Pattern mismatch (expected: #{test_case[:expected_pattern]}, got: #{pattern_type})" unless pattern_match
      failure_reason << "No suggestions returned" unless has_suggestions
      
      puts "   ❌ FAILED - #{failure_reason.join(', ')}"
      failed_tests += 1
      results << {
        service: test_case[:service_class].name,
        question: test_case[:question],
        status: "FAILED",
        reason: failure_reason.join(', '),
        pattern_type: pattern_type,
        suggestions_count: suggestions_count
      }
    end
    
    # Also test the service directly
    puts "   📋 Direct service test:"
    service_instance = test_case[:service_class].new(test_case[:question])
    match_result = service_instance.send(:match_pattern)
    
    if match_result[:matched]
      puts "     ✅ Service match_pattern: SUCCESS"
    else
      puts "     ❌ Service match_pattern: FAILED"
    end
    
  rescue => e
    puts "   ❌ ERROR: Exception occurred - #{e.message}"
    puts "   Backtrace: #{e.backtrace.first(2).join(', ')}"
    failed_tests += 1
    results << {
      service: test_case[:service_class].name,
      question: test_case[:question],
      status: "ERROR",
      reason: e.message,
      pattern_type: "error",
      suggestions_count: 0
    }
  end
end

puts "\n" + "=" * 80
puts "DETAILED TEST RESULTS"
puts "=" * 80

results.each_with_index do |result, index|
  status_icon = case result[:status]
                when "PASSED" then "✅"
                when "FAILED" then "❌"
                when "ERROR" then "🔥"
                else "❓"
                end
  
  puts "#{index + 1}. #{status_icon} #{result[:service]}"
  puts "   Question: #{result[:question]}"
  puts "   Status: #{result[:status]}"
  puts "   Pattern: #{result[:pattern_type]}"
  puts "   Suggestions: #{result[:suggestions_count]}"
  puts "   Reason: #{result[:reason]}" if result[:status] != "PASSED"
  puts
end

puts "=" * 80
puts "FINAL SUMMARY"
puts "=" * 80

puts "Total tests: #{TEST_CASES.length}"
puts "Passed: #{successful_tests}"
puts "Failed: #{failed_tests}"
puts "Success rate: #{(successful_tests.to_f / TEST_CASES.length * 100).round(2)}%"

# Group failures by type
if failed_tests > 0
  puts "\nFailure breakdown:"
  
  pattern_failures = results.select { |r| r[:reason].include?("Pattern mismatch") }
  suggestion_failures = results.select { |r| r[:reason].include?("No suggestions") }
  error_failures = results.select { |r| r[:status] == "ERROR" }
  
  puts "- Pattern matching failures: #{pattern_failures.length}"
  puts "- No suggestions failures: #{suggestion_failures.length}"
  puts "- Exception errors: #{error_failures.length}"
  
  if pattern_failures.any?
    puts "\nPattern matching issues:"
    pattern_failures.each do |failure|
      puts "  - #{failure[:service]}: #{failure[:question]}"
    end
  end
  
  if suggestion_failures.any?
    puts "\nNo suggestions issues:"
    suggestion_failures.each do |failure|
      puts "  - #{failure[:service]}: #{failure[:question]}"
    end
  end
  
  if error_failures.any?
    puts "\nException errors:"
    error_failures.each do |failure|
      puts "  - #{failure[:service]}: #{failure[:reason]}"
    end
  end
end

puts "\n" + "=" * 80

if failed_tests == 0
  puts "🎉 ALL SERVICE COMBINATIONS WORKING CORRECTLY!"
  puts "The question processing system is functioning properly."
  exit 0
else
  puts "⚠️  SOME SERVICE COMBINATIONS NEED ATTENTION"
  puts "Use the debug_service.rb script to investigate specific failures."
  exit 1
end

namespace :test do
  desc "Test question records from a json file and output results to CSV with comprehensive logging"
  # Usage: bundle exec rails "test:test_question_records[txt/all_grid_questions.json]"
  # 
  # Input file format (JSON):
  # {
  #   "1": ["Cincinnati Reds + All Star", "Silver Slugger + Gold Glove", ...],
  #   "2": ["MVP + Chicago Cubs", "40+ WAR Career + 300+ HR Career Batting", ...],
  #   ...
  # }
  # 
  # Output: 
  # - questions_historical.csv with test results
  # - log/test_question_records_TIMESTAMP.log with detailed logs
  # - Terminal output with real-time progress
  # - Rails development.log with integration logs
  task :test_question_records, [:input_file] => :environment do |task, args|
    require 'csv'
    require 'json'
    
    input_file = args[:input_file]
    unless input_file
      message = "Usage: rails test:test_question_records[path/to/input.json]"
      puts message
      exit 1
    end
    
    unless File.exist?(input_file)
      message = "Error: File not found: #{input_file}"
      puts message
      exit 1
    end
    
    # Parse JSON file
    begin
      json_data = JSON.parse(File.read(input_file))
    rescue JSON::ParserError => e
      message = "Error: Invalid JSON format in #{input_file}: #{e.message}"
      puts message
      exit 1
    end
    
    # Setup logging
    logger = Rails.logger
    
    # Create a timestamped log file for this specific test run
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    test_log_file = "log/test_question_records_#{timestamp}.log"
    
    # Create a custom logger for this task
    task_logger = Logger.new(test_log_file)
    task_logger.level = Logger::INFO
    task_logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
    end
    
    # Log to both Rails logger and task-specific logger
    def log_message(rails_logger, task_logger, level, message)
      rails_logger.send(level, message)
      task_logger.send(level, message)
    end
    
    log_message(logger, task_logger, :info, "=" * 80)
    log_message(logger, task_logger, :info, "Starting test_question_records task")
    log_message(logger, task_logger, :info, "Input file: #{input_file}")
    log_message(logger, task_logger, :info, "Task log file: #{test_log_file}")
    log_message(logger, task_logger, :info, "=" * 80)
    
    # Array to store results for CSV output
    results = []
    total_tests = 0
    passed_tests = 0
    failed_tests = 0
    
    start_time = Time.current
    
    message = "Testing question records from: #{input_file}"
    puts message
    log_message(logger, task_logger, :info, message)
    
    puts "=" * 60
    log_message(logger, task_logger, :info, "=" * 60)
    
    # Process each object in the JSON
    json_data.each do |object_id, questions_array|
      unless questions_array.is_a?(Array)
        message = "Object #{object_id}: SKIP - Value is not an array"
        puts message
        log_message(logger, task_logger, :warn, message)
        next
      end
      
      unless questions_array.length == 9
        message = "Object #{object_id}: SKIP - Array does not contain exactly 9 questions (found #{questions_array.length})"
        puts message
        log_message(logger, task_logger, :warn, message)
        next
      end
      
      log_message(logger, task_logger, :info, "Processing object #{object_id} with #{questions_array.length} questions")
      
      questions_array.each_with_index do |question, question_index|
        begin
          log_message(logger, task_logger, :info, "Processing object #{object_id}, question #{question_index + 1}: #{question}")
          
          # Test the question through the processor service
          result = Questions::ProcessorService.call([question])
          
          if result && result.first
            question_result = result.first
            suggestions_count = question_result[:suggestions]&.length || 0
            pattern_type = question_result[:pattern_type]
            
            if pattern_type == "unmatched" || suggestions_count == 0
              status = "FAIL[0]"
              failed_tests += 1
              log_level = :warn
            else
              status = "PASS[#{suggestions_count}]"
              passed_tests += 1
              log_level = :info
            end
            
            message = "Object #{object_id}, Q#{question_index + 1}: #{status} - #{question} (#{pattern_type})"
            puts message
            log_message(logger, task_logger, log_level, message)
            
            # Add to results array for CSV
            results << {
              object_id: object_id,
              question_index: question_index + 1,
              question: question,
              status: status.include?("PASS") ? "PASS" : "FAIL",
              suggestions_count: suggestions_count,
              pattern_type: pattern_type
            }
          else
            message = "Object #{object_id}, Q#{question_index + 1}: FAIL[0] - #{question} (service error)"
            puts message
            log_message(logger, task_logger, :error, message)
            failed_tests += 1
            
            results << {
              object_id: object_id,
              question_index: question_index + 1,
              question: question,
              status: "FAIL",
              suggestions_count: 0,
              pattern_type: "service_error"
            }
          end
          
          total_tests += 1
          
        rescue => e
          message = "Object #{object_id}, Q#{question_index + 1}: ERROR - #{question} (#{e.message})"
          puts message
          log_message(logger, task_logger, :error, "#{message} - Backtrace: #{e.backtrace.first(3).join(', ')}")
          failed_tests += 1
          
          results << {
            object_id: object_id,
            question_index: question_index + 1,
            question: question,
            status: "ERROR",
            suggestions_count: 0,
            pattern_type: "parse_error"
          }
          
          total_tests += 1
        end
      end
    end
    
    # Write results to CSV
    csv_file = "questions_historical.csv"
    log_message(logger, task_logger, :info, "Writing results to CSV: #{csv_file}")
    
    CSV.open(csv_file, 'w', write_headers: true, headers: [
      'Object ID',
      'Question Index',
      'Question',
      'Status',
      'Suggestions Count',
      'Pattern Type'
    ]) do |csv|
      results.each do |result|
        csv << [
          result[:object_id],
          result[:question_index],
          result[:question],
          result[:status],
          result[:suggestions_count],
          result[:pattern_type]
        ]
      end
    end
    
    end_time = Time.current
    duration = (end_time - start_time).round(2)
    
    puts "=" * 60
    log_message(logger, task_logger, :info, "=" * 60)
    
    summary_lines = [
      "Test Summary:",
      "Total tests: #{total_tests}",
      "Passed: #{passed_tests}",
      "Failed: #{failed_tests}",
      "Success rate: #{total_tests > 0 ? (passed_tests.to_f / total_tests * 100).round(2) : 0}%",
      "Duration: #{duration} seconds",
      "Results written to: #{csv_file}",
      "Detailed logs written to: #{test_log_file}"
    ]
    
    summary_lines.each do |line|
      puts line
      log_message(logger, task_logger, :info, line)
    end
    
    log_message(logger, task_logger, :info, "=" * 80)
    log_message(logger, task_logger, :info, "Completed test_question_records task")
    log_message(logger, task_logger, :info, "=" * 80)
    
    # Close the task logger
    task_logger.close
  end
end

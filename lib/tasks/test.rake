namespace :test do
  desc "Test question records from a txt file and output results to CSV with comprehensive logging"
  # Usage: bundle exec rails "test:test_question_records[path/to/input.txt]"
  # 
  # Input file format (one per line):
  # ['Cincinnati Reds', 'All Star']
  # ['Silver Slugger', 'Gold Glove']
  # ['MVP', 'Chicago Cubs']
  # 
  # Output: 
  # - questions_historical.csv with test results
  # - log/test_question_records_TIMESTAMP.log with detailed logs
  # - Terminal output with real-time progress
  # - Rails development.log with integration logs
  task :test_question_records, [:input_file] => :environment do |task, args|
    require 'csv'
    
    input_file = args[:input_file]
    unless input_file
      message = "Usage: rails test:test_question_records[path/to/input.txt]"
      puts message
      exit 1
    end
    
    unless File.exist?(input_file)
      message = "Error: File not found: #{input_file}"
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
    
    File.readlines(input_file, chomp: true).each_with_index do |line, index|
      next if line.strip.empty?
      
      begin
        # Parse the array format: ['Cincinnati Reds', 'All Star']
        # Remove quotes and brackets, split by comma
        cleaned_line = line.strip.gsub(/[\[\]']/, '').split(',').map(&:strip)
        
        if cleaned_line.length != 2
          message = "Line #{index + 1}: SKIP - Invalid format (expected 2 elements): #{line}"
          puts message
          log_message(logger, task_logger, :warn, message)
          next
        end
        
        # Convert to question format: "Cincinnati Reds + All Star"
        question = cleaned_line.join(' + ')
        
        log_message(logger, task_logger, :info, "Processing line #{index + 1}: #{question}")
        
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
          
          message = "Line #{index + 1}: #{status} - #{question} (#{pattern_type})"
          puts message
          log_message(logger, task_logger, log_level, message)
          
          # Add to results array for CSV
          results << {
            line_number: index + 1,
            original_input: line,
            question: question,
            status: status.include?("PASS") ? "PASS" : "FAIL",
            suggestions_count: suggestions_count,
            pattern_type: pattern_type
          }
        else
          message = "Line #{index + 1}: FAIL[0] - #{question} (service error)"
          puts message
          log_message(logger, task_logger, :error, message)
          failed_tests += 1
          
          results << {
            line_number: index + 1,
            original_input: line,
            question: question,
            status: "FAIL",
            suggestions_count: 0,
            pattern_type: "service_error"
          }
        end
        
        total_tests += 1
        
      rescue => e
        message = "Line #{index + 1}: ERROR - #{line} (#{e.message})"
        puts message
        log_message(logger, task_logger, :error, "#{message} - Backtrace: #{e.backtrace.first(3).join(', ')}")
        failed_tests += 1
        
        results << {
          line_number: index + 1,
          original_input: line,
          question: "ERROR",
          status: "ERROR",
          suggestions_count: 0,
          pattern_type: "parse_error"
        }
        
        total_tests += 1
      end
    end
    
    # Write results to CSV
    csv_file = "questions_historical.csv"
    log_message(logger, task_logger, :info, "Writing results to CSV: #{csv_file}")
    
    CSV.open(csv_file, 'w', write_headers: true, headers: [
      'Line Number',
      'Original Input',
      'Question',
      'Status',
      'Suggestions Count',
      'Pattern Type'
    ]) do |csv|
      results.each do |result|
        csv << [
          result[:line_number],
          result[:original_input],
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

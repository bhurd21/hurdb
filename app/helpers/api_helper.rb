module ApiHelper
  # Helper method to safely parse and ingest the questions query parameter
  def ingest_questions_param
    questions_param = params[:questions] || "[]"
    
    JSON.parse(questions_param)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse questions JSON: #{e.message}"
    []
  end

  # Process each query value in the array
  def process_queries(questions)
    Rails.logger.info "Processing questions: #{questions.inspect}"
    
    questions.map.with_index do |question, index|
      process_query(question, index)
    end
  end

  # Main query processing method with submethods
  def process_query(question, index = 0)
    query = build_query(question)
    suggestions = execute_query(query)
    
    {
      label: question,
      suggestions: suggestions
    }
  end

  # Build the query based on the input question
  def build_query(question)
    # TODO: Implement actual query building logic when DB is ready
    # For now, return a simple query structure
    {
      term: question,
      type: :player_search,
      filters: {}
    }
  end

  # Execute the built query and return results
  def execute_query(query)
    # TODO: Implement actual database query execution when DB is ready
    # For now, return dummy data that matches the expected format
    [
      "Dummy Player rails1",
      "Dummy Player rails2", 
      "Dummy Player rails3"
    ]
  end
end

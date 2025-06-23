module ApiHelper
  # Helper method to safely parse and ingest the questions query parameter
  def ingest_questions_param
    questions_param = params[:questions] || "[]"
    
    JSON.parse(questions_param)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse questions JSON: #{e.message}"
    []
  end

  # Process each query value in the array using the Questions::ProcessorService
  def process_queries(questions)
    Questions::ProcessorService.call(questions)
  end
end

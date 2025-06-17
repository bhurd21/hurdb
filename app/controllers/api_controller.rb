class ApiController < ApplicationController
  include ApiHelper
  
  allow_unauthenticated_access only: %i[ imgrid ]
  
  def imgrid
    # Restrict to only accept 'questions' parameter
    sanitized_params = params.permit(:questions)
    
    questions = ingest_questions_param
    results = process_queries(questions)
    
    render json: { suggestions: results }
  end

  private

  # Override params to use only sanitized parameters
  def params
    @sanitized_params ||= super.permit(:questions)
  end
end

class Questions::ProcessorService
  # Registry of available question services
  QUESTION_SERVICES = [
    Questions::TeamTeamService,
    Questions::TeamStatService,
    Questions::TeamPositionService,
    Questions::TeamPlayerService,
    Questions::StatStatService,
    Questions::StatPositionService,
    Questions::StatPlayerService,
    Questions::PositionPositionService,
    Questions::PositionPlayerService,
    Questions::PlayerPlayerService
  ].freeze

  def self.call(questions)
    new(questions).call
  end

  def initialize(questions)
    @questions = questions
  end

  def call
    Rails.logger.info "Processing questions: #{@questions.inspect}"
    
    @questions.map.with_index do |question, index|
      process_single_question(question, index)
    end
  end

  private

  def process_single_question(question, index = 0)
    # Try each question service until one matches
    QUESTION_SERVICES.each do |service_class|
      result = service_class.call(question)
      return result if result[:pattern_type] != "unmatched"
    end

    # No pattern matched
    {
      label: question,
      suggestions: [],
      pattern_type: "unmatched"
    }
  end
end

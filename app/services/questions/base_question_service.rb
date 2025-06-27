class Questions::BaseQuestionService
  include DataLookupHelper

  def self.call(question)
    new(question).call
  end

  def initialize(question)
    @question = question
  end

  def call
    result = match_pattern
    return unmatched_result unless result[:matched]

    suggestions = execute_query(result[:data])
    {
      label: @question,
      suggestions: suggestions.first(100),
      pattern_type: pattern_name
    }
  rescue => e
    Rails.logger.error "Query execution failed for #{pattern_name}: #{e.message}"
    Rails.logger.error "Question: #{@question}"
    unmatched_result
  end

  private

  def pattern_name
    self.class.name.demodulize.underscore.gsub('_service', '')
  end

  def unmatched_result
    {
      label: @question,
      suggestions: [],
      pattern_type: "unmatched"
    }
  end

  def execute_query(data)
    sql = build_query(data)
    execute_sql(sql)
  end

  def execute_sql(sql)
    results = ActiveRecord::Base.connection.execute(sql)
    results.map(&:to_h)
  rescue => e
    Rails.logger.error "SQL execution failed: #{e.message}"
    Rails.logger.error "SQL: #{sql}"
    []
  end

  # Subclasses must implement these methods
  def match_pattern
    raise NotImplementedError, "Subclasses must implement match_pattern"
  end

  def build_query(data)
    raise NotImplementedError, "Subclasses must implement build_query"
  end
end

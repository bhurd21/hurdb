module Questions::Concerns::QueryBuilder
  extend ActiveSupport::Concern

  private

  def format_table_name(table)
    table.downcase.pluralize
  end

  def format_operator_sql(operator)
    operator == 'gte' ? '>=' : '<='
  end

  def split_and_validate_conditions(question)
    conditions = question.split(/\s\+\s/).map(&:strip)
    return nil unless conditions.length == 2
    conditions
  end
end

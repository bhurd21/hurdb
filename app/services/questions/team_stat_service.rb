class Questions::TeamStatService < Questions::BaseQuestionService
  private

  def match_pattern
    conditions = @question.split(/\s\+\s/).map(&:strip)
    return { matched: false } unless conditions.length == 2

    team_condition = conditions.find { |c| team_lookup.key?(c) }
    stat_condition = conditions.find { |c| c.match?(/Season|Career/i) }
    return { matched: false } unless team_condition && stat_condition

    timeframe = stat_condition[/Season|Career/i]&.capitalize
    return { matched: false } unless timeframe

    stat_match = stat_condition.match(/\b(?<value>\<?\.?\d+(?:\.\d+)?)(?<op>\+)?\s(?<stat>[A-Za-z]+)\s(Season|Career)\b/i)
    return { matched: false } unless stat_match
    
    value = stat_match[:value]
    stat_name = stat_match[:stat].strip.upcase
    stat_object = stat_lookup[stat_name]
    return { matched: false } unless stat_object

    team_abbr = team_lookup[team_condition]
    return { matched: false } unless team_abbr

    {
      matched: true,
      data: {
        team_abbr: team_abbr,
        stat_value: value.to_f,
        timeframe: timeframe,
        stat_name: stat_name,
        stat_column: stat_object['column'],
        stat_operator: stat_object['operator'],
        stat_table: stat_object['table']
      }
    }
  end

  def build_query(data)
    team_abbr = data[:team_abbr]
    stat_value = data[:stat_value]
    timeframe = data[:timeframe]
    stat_name = data[:stat_name]
    stat_column = data[:stat_column]
    stat_operator = data[:stat_operator]
    stat_table = data[:stat_table]
    
    table_name = stat_table.downcase.pluralize
    operator_sql = stat_operator == 'gte' ? '>=' : '<='
    stat_sql = build_stat_sql(stat_name, stat_column)

    if timeframe == 'Season'
      build_season_query(table_name, team_abbr, stat_sql, operator_sql, stat_value)
    else
      build_career_query(table_name, team_abbr, stat_sql, operator_sql, stat_value)
    end
  end

  def build_stat_sql(stat_name, stat_column)
    return "SUM(#{stat_column})" if stat_column

    case stat_name
    when 'AVG'
      'CAST(SUM(h) AS FLOAT) / SUM(ab)'
    when 'ERA'
      'CAST(SUM(er) AS FLOAT) / SUM(ip_outs) * 27'
    else
      raise "Unknown stat name: #{stat_name}"
    end
  end

  def build_season_query(table_name, team_abbr, stat_sql, operator_sql, stat_value)
    <<~SQL
      WITH initial_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          WHERE team_id = '#{team_abbr}'
          GROUP BY player_id, year_id
          HAVING #{stat_sql} #{operator_sql} #{stat_value}
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        'XX' as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        null as lps,
        p.bbref_id
      FROM initial_condition ic
      LEFT JOIN people p ON p.player_id = ic.player_id
      ORDER BY age DESC;
    SQL
  end

  def build_career_query(table_name, team_abbr, stat_sql, operator_sql, stat_value)
    <<~SQL
      WITH stat_condition AS (
          SELECT DISTINCT player_id
          FROM #{table_name}
          GROUP BY player_id
          HAVING #{stat_sql} #{operator_sql} #{stat_value}
      ),
      team_condition AS (
          SELECT DISTINCT player_id
          FROM appearances
          WHERE team_id = '#{team_abbr}'
      )
      SELECT
        CONCAT(p.name_first, ' ', p.name_last) AS name,
        'XX' as position,
        substr(p.debut, 1, 4) || '-' || substr(p.final_game, 1, 4) AS pro_career,
        2025 - p.birth_year AS age,
        null as lps,
        p.bbref_id
      FROM stat_condition sc
      LEFT JOIN people p ON p.player_id = sc.player_id
      WHERE sc.player_id IN (SELECT player_id FROM team_condition)
      ORDER BY age DESC;
    SQL
  end
end

class Person < ApplicationRecord
  has_many :batting_records, class_name: 'Batting', foreign_key: :player_id, primary_key: :player_id
  has_many :pitching_records, class_name: 'Pitching', foreign_key: :player_id, primary_key: :player_id
  has_many :all_star_fulls, foreign_key: :player_id, primary_key: :player_id
  has_many :appearances, foreign_key: :player_id, primary_key: :player_id
  has_many :awards_players, foreign_key: :player_id, primary_key: :player_id
  has_many :hall_of_fames, foreign_key: :player_id, primary_key: :player_id
  
  def full_name
    "#{name_first} #{name_last}".strip
  end
  
  def age
    return nil unless birth_year
    Date.current.year - birth_year.to_i
  end
end

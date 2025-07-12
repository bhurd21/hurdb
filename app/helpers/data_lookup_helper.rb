module DataLookupHelper
  # Team abbreviations mapping
  def self.team_lookup
    @team_lookup ||= {
      "Washington Nationals" =>     "WAS",
      "Toronto Blue Jays" =>        "TOR",
      "Texas Rangers" =>            "TEX",
      "Tampa Bay Rays" =>           "TBA",
      "St. Louis Cardinals" =>      "SLN",
      "San Francisco Giants" =>     "SFN",
      "Seattle Mariners" =>         "SEA",
      "San Diego Padres" =>         "SDN",
      "Pittsburgh Pirates" =>       "PIT",
      "Philadelphia Phillies" =>    "PHI",
      "Oakland Athletics" =>        "OAK",
      "Athletics" =>                "OAK",
      "New York Yankees" =>         "NYA",
      "New York Mets" =>            "NYN",
      "Minnesota Twins" =>          "MIN",
      "Milwaukee Brewers" =>        "MIL",
      "Los Angeles Dodgers" =>      "LAN",
      "Kansas City Royals" =>       "KCA",
      "Houston Astros" =>           "HOU",
      "Miami Marlins" =>            "MIA",
      "Detroit Tigers" =>           "DET",
      "Colorado Rockies" =>         "COL",
      "Cleveland Guardians" =>      "CLE",
      "Cincinnati Reds" =>          "CIN",
      "Chicago White Sox" =>        "CHA",
      "Chicago Cubs" =>             "CHN",
      "Boston Red Sox" =>           "BOS",
      "Baltimore Orioles" =>        "BAL",
      "Atlanta Braves" =>           "ATL",
      "Arizona Diamondbacks" =>     "ARI",
      "Los Angeles Angels" =>       "LAA",
    }.freeze
  end

  def self.stat_lookup
    @stat_lookup ||= {
      'HITS' =>   { 'column' => 'h',       'operator' => 'gte', 'table' => 'Batting'  },
      'HR' =>     { 'column' => 'hr',      'operator' => 'gte', 'table' => 'Batting'  },
      'RBI' =>    { 'column' => 'rbi',     'operator' => 'gte', 'table' => 'Batting'  },
      'AVG' =>    { 'column' => nil,       'operator' => 'gte', 'table' => 'Batting'  },
      'RUN' =>    { 'column' => 'r',       'operator' => 'gte', 'table' => 'Batting'  },
      'SB' =>     { 'column' => 'sb',      'operator' => 'gte', 'table' => 'Batting'  },
      '2B' =>     { 'column' => 'doubles', 'operator' => 'gte', 'table' => 'Batting'  },
      'WIN' =>    { 'column' => 'w',       'operator' => 'gte', 'table' => 'Pitching' },
      'WINS' =>   { 'column' => 'w',       'operator' => 'gte', 'table' => 'Pitching' },
      'ERA' =>    { 'column' => nil,       'operator' => 'lte', 'table' => 'Pitching' },
      'K' =>      { 'column' => 'so',      'operator' => 'gte', 'table' => 'Pitching' },
      'SAVE' =>   { 'column' => 'sv',      'operator' => 'gte', 'table' => 'Pitching' },
    }.freeze
  end

  def self.position_lookup
    @position_lookup ||= {
      'Pitcher' => 'g_p',
      'Catcher' => 'g_c',
      'First Base' => 'g_1b',
      'Second Base' => 'g_2b',
      'Third Base' => 'g_3b',
      'Shortstop' => 'g_ss',
      'Left Field' => 'g_lf',
      'Center Field' => 'g_cf',
      'Right Field' => 'g_rf',
      'Outfield' => 'g_of',
      'DH' => 'g_dh',
      'Designated Hitter' => 'g_dh',
      'Pinch Hitter' => 'g_ph',
      'Pinch Runner' => 'g_pr'
    }.freeze
  end

  def self.player_lookup
    @player_lookup ||= {
      'Born Outside US 50 States and DC' => 'birth_country != \'USA\'',
      'Canada' => 'birth_country = \'CAN\'',
      'Dominican Republic' => 'birth_country = \'D.R.\'',
      'Puerto Rico' => 'birth_country = \'P.R.\'',
      'United States' => 'birth_country = \'USA\'',
      'Played Major Leagues' => '1 = 1',
      'World Series Champ WS Roster' => 'is_ws_champ = 1',
      'Only One Team' => 'matches_only_one_team = 1',
      '40+ WAR Career' => 'bwar_career >= 40',
      'Hall of Fame' => 'hall_of_fame = 1',
      '6+ WAR Season' => 'has_6_war_season = 1',
      'Threw a No-Hitter' => 'has_no_hitter = 1'
    }.freeze
  end

  def self.award_lookup
    @award_lookup ||= {
      'Silver Slugger' => 'Silver Slugger',
      'MVP' => 'Most Valuable Player',
      'Gold Glove' => 'Gold Glove',
      'Cy Young' => 'Cy Young Award',
      'Rookie of the Year' => 'Rookie of the Year',
      'All Star' => 'All Star'
    }.freeze
  end

  # Convenience methods for accessing lookups
  def team_lookup
    DataLookupHelper.team_lookup
  end

  def stat_lookup
    DataLookupHelper.stat_lookup
  end

  def position_lookup
    DataLookupHelper.position_lookup
  end

  def player_lookup
    DataLookupHelper.player_lookup
  end

  def award_lookup
    DataLookupHelper.award_lookup
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_12_044006) do
  create_table "all_star_fulls", force: :cascade do |t|
    t.string "player_id"
    t.integer "year_id"
    t.integer "game_num"
    t.string "game_id"
    t.string "team_id"
    t.string "lg_id"
    t.integer "gp"
    t.string "starting_pos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_all_star_fulls_on_player_id"
  end

  create_table "appearances", force: :cascade do |t|
    t.integer "year_id"
    t.string "team_id"
    t.string "lg_id"
    t.string "player_id"
    t.integer "g_all"
    t.float "gs"
    t.integer "g_batting"
    t.float "g_defense"
    t.integer "g_p"
    t.integer "g_c"
    t.integer "g_1b"
    t.integer "g_2b"
    t.integer "g_3b"
    t.integer "g_ss"
    t.integer "g_lf"
    t.integer "g_cf"
    t.integer "g_rf"
    t.integer "g_of"
    t.float "g_dh"
    t.float "g_ph"
    t.float "g_pr"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "team_id"], name: "index_appearances_on_player_id_and_team_id"
    t.index ["player_id"], name: "index_appearances_on_player_id"
    t.index ["team_id", "year_id"], name: "index_appearances_on_team_id_and_year_id"
    t.index ["team_id"], name: "index_appearances_on_team_id"
    t.index ["year_id"], name: "index_appearances_on_year_id"
  end

  create_table "awards_players", force: :cascade do |t|
    t.string "player_id"
    t.string "award_id"
    t.integer "year_id"
    t.string "lg_id"
    t.string "tie"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_awards_players_on_player_id"
  end

  create_table "battings", force: :cascade do |t|
    t.string "player_id"
    t.integer "year_id"
    t.integer "stint"
    t.string "team_id"
    t.string "lg_id"
    t.integer "g"
    t.string "g_batting"
    t.integer "ab"
    t.integer "r"
    t.integer "h"
    t.integer "doubles"
    t.integer "triples"
    t.integer "hr"
    t.float "rbi"
    t.float "sb"
    t.float "cs"
    t.integer "bb"
    t.float "so"
    t.float "ibb"
    t.float "hbp"
    t.float "sh"
    t.float "sf"
    t.float "gidp"
    t.string "g_old"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_battings_on_player_id"
    t.index ["team_id"], name: "index_battings_on_team_id"
  end

  create_table "hall_of_fames", force: :cascade do |t|
    t.string "player_id"
    t.integer "year_id"
    t.string "voted_by"
    t.float "ballots"
    t.float "needed"
    t.float "votes"
    t.string "inducted"
    t.string "category"
    t.string "needed_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_hall_of_fames_on_player_id"
    t.index ["voted_by", "inducted"], name: "index_hall_of_fames_on_voted_by_and_inducted"
  end

  create_table "people", force: :cascade do |t|
    t.string "player_id"
    t.float "birth_year"
    t.float "birth_month"
    t.float "birth_day"
    t.string "birth_city"
    t.string "birth_country"
    t.string "birth_state"
    t.string "death_year"
    t.string "death_month"
    t.string "death_day"
    t.string "death_country"
    t.string "death_state"
    t.string "death_city"
    t.string "name_first"
    t.string "name_last"
    t.string "name_given"
    t.string "weight"
    t.string "height"
    t.string "bats"
    t.string "throws"
    t.string "debut"
    t.string "bbref_id"
    t.string "final_game"
    t.string "retro_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "bwar_career"
    t.string "primary_position"
    t.boolean "hall_of_fame", default: false
    t.boolean "is_ws_champ", default: false
    t.boolean "matches_only_one_team", default: false
    t.boolean "has_6_war_season", default: false
    t.boolean "has_no_hitter", default: false
    t.index ["hall_of_fame"], name: "index_people_on_hall_of_fame"
    t.index ["is_ws_champ"], name: "index_people_on_is_ws_champ"
    t.index ["matches_only_one_team"], name: "index_people_on_matches_only_one_team"
    t.index ["player_id"], name: "index_people_on_player_id"
  end

  create_table "pitchings", force: :cascade do |t|
    t.string "player_id"
    t.integer "year_id"
    t.integer "stint"
    t.string "team_id"
    t.string "lg_id"
    t.integer "w"
    t.integer "l"
    t.integer "g"
    t.integer "gs"
    t.integer "cg"
    t.integer "sho"
    t.integer "sv"
    t.integer "ip_outs"
    t.integer "h"
    t.integer "er"
    t.integer "hr"
    t.integer "bb"
    t.integer "so"
    t.float "ba_opp"
    t.float "era"
    t.float "ibb"
    t.integer "wp"
    t.float "hbp"
    t.integer "bk"
    t.float "bfp"
    t.integer "gf"
    t.integer "r"
    t.float "sh"
    t.float "sf"
    t.float "gidp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_pitchings_on_player_id"
    t.index ["team_id"], name: "index_pitchings_on_team_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.integer "year_id"
    t.string "lg_id"
    t.string "team_id"
    t.string "franch_id"
    t.string "div_id"
    t.integer "rank"
    t.integer "g"
    t.float "g_home"
    t.integer "w"
    t.integer "l"
    t.string "div_win"
    t.string "wc_win"
    t.string "lg_win"
    t.string "ws_win"
    t.integer "r"
    t.integer "ab"
    t.integer "h"
    t.integer "doubles"
    t.integer "triples"
    t.integer "hr"
    t.integer "bb"
    t.float "so"
    t.float "sb"
    t.float "cs"
    t.float "hbp"
    t.float "sf"
    t.integer "ra"
    t.integer "er"
    t.float "era"
    t.integer "cg"
    t.integer "sho"
    t.integer "sv"
    t.integer "ip_outs"
    t.integer "ha"
    t.integer "hra"
    t.integer "bba"
    t.integer "soa"
    t.integer "e"
    t.integer "dp"
    t.float "fp"
    t.string "name"
    t.string "park"
    t.float "attendance"
    t.integer "bpf"
    t.integer "ppf"
    t.string "team_id_br"
    t.string "team_id_lahman45"
    t.string "team_id_retro"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "year_id"], name: "index_teams_on_team_id_and_year_id"
    t.index ["team_id"], name: "index_teams_on_team_id"
    t.index ["ws_win"], name: "index_teams_on_ws_win"
    t.index ["year_id"], name: "index_teams_on_year_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "sessions", "users"
end

class CreateAllStarFulls < ActiveRecord::Migration[8.0]
  def change
    create_table :all_star_fulls do |t|
      t.string :player_id
      t.integer :year_id
      t.integer :game_num
      t.string :game_id
      t.string :team_id
      t.string :lg_id
      t.integer :gp
      t.string :starting_pos

      t.timestamps
    end
  end
end

class CreateAwardsPlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :awards_players do |t|
      t.string :player_id
      t.string :award_id
      t.integer :year_id
      t.string :lg_id
      t.string :tie
      t.text :notes

      t.timestamps
    end
  end
end

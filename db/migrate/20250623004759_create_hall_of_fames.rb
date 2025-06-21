class CreateHallOfFames < ActiveRecord::Migration[8.0]
  def change
    create_table :hall_of_fames do |t|
      t.string :player_id
      t.integer :year_id
      t.string :voted_by
      t.float :ballots
      t.float :needed
      t.float :votes
      t.string :inducted
      t.string :category
      t.string :needed_note

      t.timestamps
    end
  end
end

class CreatePeople < ActiveRecord::Migration[8.0]
  def change
    create_table :people do |t|
      t.string :player_id
      t.float :birth_year
      t.float :birth_month
      t.float :birth_day
      t.string :birth_city
      t.string :birth_country
      t.string :birth_state
      t.string :death_year
      t.string :death_month
      t.string :death_day
      t.string :death_country
      t.string :death_state
      t.string :death_city
      t.string :name_first
      t.string :name_last
      t.string :name_given
      t.string :weight
      t.string :height
      t.string :bats
      t.string :throws
      t.string :debut
      t.string :bbref_id
      t.string :final_game
      t.string :retro_id

      t.timestamps
    end
  end
end

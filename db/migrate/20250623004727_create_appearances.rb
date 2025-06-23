class CreateAppearances < ActiveRecord::Migration[8.0]
  def change
    create_table :appearances do |t|
      t.integer :year_id
      t.string :team_id
      t.string :lg_id
      t.string :player_id
      t.integer :g_all
      t.float :gs
      t.integer :g_batting
      t.float :g_defense
      t.integer :g_p
      t.integer :g_c
      t.integer :g_1b
      t.integer :g_2b
      t.integer :g_3b
      t.integer :g_ss
      t.integer :g_lf
      t.integer :g_cf
      t.integer :g_rf
      t.integer :g_of
      t.float :g_dh
      t.float :g_ph
      t.float :g_pr

      t.timestamps
    end
  end
end

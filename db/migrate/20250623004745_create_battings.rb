class CreateBattings < ActiveRecord::Migration[8.0]
  def change
    create_table :battings do |t|
      t.string :player_id
      t.integer :year_id
      t.integer :stint
      t.string :team_id
      t.string :lg_id
      t.integer :g
      t.string :g_batting
      t.integer :ab
      t.integer :r
      t.integer :h
      t.integer :doubles
      t.integer :triples
      t.integer :hr
      t.float :rbi
      t.float :sb
      t.float :cs
      t.integer :bb
      t.float :so
      t.float :ibb
      t.float :hbp
      t.float :sh
      t.float :sf
      t.float :gidp
      t.string :g_old

      t.timestamps
    end
  end
end

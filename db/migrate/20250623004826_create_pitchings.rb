class CreatePitchings < ActiveRecord::Migration[8.0]
  def change
    create_table :pitchings do |t|
      t.string :player_id
      t.integer :year_id
      t.integer :stint
      t.string :team_id
      t.string :lg_id
      t.integer :w
      t.integer :l
      t.integer :g
      t.integer :gs
      t.integer :cg
      t.integer :sho
      t.integer :sv
      t.integer :ip_outs
      t.integer :h
      t.integer :er
      t.integer :hr
      t.integer :bb
      t.integer :so
      t.float :ba_opp
      t.float :era
      t.float :ibb
      t.integer :wp
      t.float :hbp
      t.integer :bk
      t.float :bfp
      t.integer :gf
      t.integer :r
      t.float :sh
      t.float :sf
      t.float :gidp

      t.timestamps
    end
  end
end

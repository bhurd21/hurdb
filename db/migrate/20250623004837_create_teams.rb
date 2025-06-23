class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.integer :year_id
      t.string :lg_id
      t.string :team_id
      t.string :franch_id
      t.string :div_id
      t.integer :rank
      t.integer :g
      t.float :g_home
      t.integer :w
      t.integer :l
      t.string :div_win
      t.string :wc_win
      t.string :lg_win
      t.string :ws_win
      t.integer :r
      t.integer :ab
      t.integer :h
      t.integer :doubles
      t.integer :triples
      t.integer :hr
      t.integer :bb
      t.float :so
      t.float :sb
      t.float :cs
      t.float :hbp
      t.float :sf
      t.integer :ra
      t.integer :er
      t.float :era
      t.integer :cg
      t.integer :sho
      t.integer :sv
      t.integer :ip_outs
      t.integer :ha
      t.integer :hra
      t.integer :bba
      t.integer :soa
      t.integer :e
      t.integer :dp
      t.float :fp
      t.string :name
      t.string :park
      t.float :attendance
      t.integer :bpf
      t.integer :ppf
      t.string :team_id_br
      t.string :team_id_lahman45
      t.string :team_id_retro

      t.timestamps
    end
  end
end

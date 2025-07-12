class AddBooleanColumnsTopeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :has_6_war_season, :boolean, default: false
    add_column :people, :has_no_hitter, :boolean, default: false
  end
end

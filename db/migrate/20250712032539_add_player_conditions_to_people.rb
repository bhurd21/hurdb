class AddPlayerConditionsToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :is_ws_champ, :boolean, default: false
    add_column :people, :matches_only_one_team, :boolean, default: false
  end
end

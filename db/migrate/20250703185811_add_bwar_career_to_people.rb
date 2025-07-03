class AddBwarCareerToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :bwar_career, :decimal
  end
end

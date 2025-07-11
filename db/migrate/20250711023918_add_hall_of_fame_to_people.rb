class AddHallOfFameToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :hall_of_fame, :boolean, default: false
  end
end

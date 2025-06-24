class AddPrimaryPositionToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :primary_position, :string
  end
end

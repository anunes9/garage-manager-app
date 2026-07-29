class AddVinAndMotorToCars < ActiveRecord::Migration[8.1]
  def change
    add_column :cars, :vin, :string
    add_column :cars, :motor, :string
  end
end

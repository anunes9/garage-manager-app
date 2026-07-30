class CreateCars < ActiveRecord::Migration[8.1]
  def change
    create_table :cars do |t|
      t.string :brand
      t.string :model
      t.string :plate
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end

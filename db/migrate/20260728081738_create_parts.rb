class CreateParts < ActiveRecord::Migration[8.1]
  def change
    create_table :parts do |t|
      t.string :name
      t.integer :quantity
      t.decimal :price, precision: 10, scale: 2
      t.references :repair, null: false, foreign_key: true

      t.timestamps
    end
  end
end

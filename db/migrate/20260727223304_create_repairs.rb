class CreateRepairs < ActiveRecord::Migration[8.1]
  def change
    create_table :repairs do |t|
      t.references :car, null: false, foreign_key: true
      t.date :date
      t.integer :km
      t.decimal :total, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end
  end
end

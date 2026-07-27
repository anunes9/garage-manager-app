class CreateRepairs < ActiveRecord::Migration[8.1]
  def change
    create_table :repairs do |t|
      t.references :car, null: false, foreign_key: true
      t.text :description
      t.decimal :cost

      t.timestamps
    end
  end
end

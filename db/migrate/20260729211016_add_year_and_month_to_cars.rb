class AddYearAndMonthToCars < ActiveRecord::Migration[8.1]
  def change
    add_column :cars, :year, :integer
    add_column :cars, :month, :integer
  end
end
